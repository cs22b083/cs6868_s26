(** A bounded channel with Go-like semantics and CML-style event support.

    {b Invariants} (must hold whenever [mutex] is not held):

    - [0 <= Queue.length buf <= capacity].
    - For plain [send]/[recv] (outside select), [receivers] has live
      entries only when [buf] is empty, and [senders] has live entries
      only when [buf] is full.
    - When [select] is used, both [receivers] and [senders] may
      contain live entries on the {i same} channel (e.g. a select
      offering both [recv_evt ch] and [send_evt ch v]).  Stale entries
      from lost select races are harmlessly skipped by
      {!find_live_receiver_locked} / {!find_live_sender_locked}.
    - Each trigger is signaled at most once ({!Trigger.signal}'s atomic
      CAS).  Stale entries may linger in the queues and are harmlessly
      skipped.
    - When a waiter's trigger is signaled, its slot holds the
      communicated value by the time the waiter observes the signal
      (happens-before via the atomic CAS in {!Trigger.signal} for
      plain [recv]/[send]; via [mutex] re-acquisition for [select]).
    - On failed signal, stale slot writes are cleared under [mutex]
      so that {!Select.select}'s [find_winner] never sees them. *)
type 'a t = {
  capacity : int;
  buf : 'a Queue.t;
  receivers : ('a option ref * Trigger.t) Queue.t;
  senders : ('a * unit option ref * Trigger.t) Queue.t;
  mutex : Mutex.t;
}

let make capacity =
  if capacity < 0 then invalid_arg "Chan.make: negative capacity";
  {
    capacity;
    buf = Queue.create ();
    receivers = Queue.create ();
    senders = Queue.create ();
    mutex = Mutex.create ();
  }

(* [find_live_receiver_locked receivers v] pops receivers until one whose
   trigger can be signaled.  Writes [slot := Some v] before signaling so
   the receiver sees the value as soon as it wakes (happens-before via
   the atomic CAS in {!Trigger.signal}).  On failed signal (stale select
   waiter), the slot is cleared to prevent {!Select.select}'s
   [find_winner] from seeing the stale write.
   Must be called with [ch.mutex] held; does NOT unlock. *)
let rec find_live_receiver_locked receivers v =
  if Queue.is_empty receivers then false
  else
    let (slot, trigger) = Queue.pop receivers in
    slot := Some v;
    if Trigger.signal trigger then true
    else begin
      slot := None;
      find_live_receiver_locked receivers v
    end

(* [find_live_sender_locked senders] pops senders until one whose trigger
   can be signaled.  Writes [done_slot := Some ()] before signaling so
   the waiter sees it as soon as it wakes (happens-before via the atomic
   CAS in {!Trigger.signal}).  On failed signal (stale select waiter),
   the slot is cleared to prevent {!Select.select}'s [find_winner] from
   seeing the stale write.
   Must be called with [ch.mutex] held; does NOT unlock. *)
let rec find_live_sender_locked senders =
  if Queue.is_empty senders then None
  else
    let (sv, done_slot, strigger) = Queue.pop senders in
    done_slot := Some ();
    if Trigger.signal strigger then
      Some sv
    else begin
      done_slot := None;
      find_live_sender_locked senders
    end

let send ch v =
  Mutex.lock ch.mutex;
  if find_live_receiver_locked ch.receivers v then begin
    (* Case 1: a waiting receiver exists -- hand off directly. *)
    Mutex.unlock ch.mutex
  end else if Queue.length ch.buf < ch.capacity then begin
    (* Case 2: buffer has room -- enqueue and return. *)
    Queue.push v ch.buf;
    Mutex.unlock ch.mutex
  end else begin
    (* Case 3: buffer full, no receivers -- block until a receiver arrives. *)
    let trigger = Trigger.create () in
    let done_slot = ref None in
    Queue.push (v, done_slot, trigger) ch.senders;
    Mutex.unlock ch.mutex;
    Trigger.await trigger
  end

let recv ch =
  Mutex.lock ch.mutex;
  if not (Queue.is_empty ch.buf) then begin
    (* Case 1: buffer non-empty -- pop head; if a sender is waiting, move
       its value into the now-free slot to preserve FIFO order. *)
    let v = Queue.pop ch.buf in
    (match find_live_sender_locked ch.senders with
     | Some sv -> Queue.push sv ch.buf
     | None -> ());
    Mutex.unlock ch.mutex;
    v
  end else begin
    match find_live_sender_locked ch.senders with
    | Some sv ->
        (* Case 2: unbuffered channel with a waiting sender -- rendezvous. *)
        Mutex.unlock ch.mutex;
        sv
    | None ->
        (* Case 3: empty buffer, no senders -- block until a sender arrives. *)
        let slot = ref None in
        let trigger = Trigger.create () in
        Queue.push (slot, trigger) ch.receivers;
        Mutex.unlock ch.mutex;
        Trigger.await trigger;
        Option.get !slot
  end

(* --- Decomposed operations for events (called under lock) --- *)

let try_complete_recv_locked ch =
  if not (Queue.is_empty ch.buf) then begin
    (* Case 1: buffer non-empty -- pop head; promote a waiting sender into
       the free slot (FIFO). *)
    let v = Queue.pop ch.buf in
    (match find_live_sender_locked ch.senders with
     | Some sv -> Queue.push sv ch.buf
     | None -> ());
    Some v
  end else begin
    match find_live_sender_locked ch.senders with
    | Some sv ->
        (* Case 2: unbuffered rendezvous with a waiting sender. *)
        Some sv
    | None ->
        (* Case 3: nothing available -- caller must offer and wait. *)
        None
  end

let try_complete_send_locked ch v =
  if find_live_receiver_locked ch.receivers v then begin
    (* Case 1: a waiting receiver exists -- hand off directly. *)
    true
  end else if Queue.length ch.buf < ch.capacity then begin
    (* Case 2: buffer has room -- enqueue. *)
    Queue.push v ch.buf;
    true
  end else begin
    (* Case 3: buffer full, no receivers -- caller must offer and wait. *)
    false
  end

let enqueue_recv_locked ch slot trigger =
  Queue.push (slot, trigger) ch.receivers

let enqueue_send_locked ch v done_slot trigger =
  Queue.push (v, done_slot, trigger) ch.senders

(* --- CML-style events --- *)

let recv_evt ch : 'a Select.event = Select.Evt {
  try_complete = (fun () -> try_complete_recv_locked ch);
  offer = (fun slot trigger -> enqueue_recv_locked ch slot trigger);
  mutex = ch.mutex;
  wrap = Fun.id;
}

let send_evt ch v : unit Select.event = Select.Evt {
  try_complete = (fun () -> if try_complete_send_locked ch v then Some () else None);
  offer = (fun done_slot trigger -> enqueue_send_locked ch v done_slot trigger);
  mutex = ch.mutex;
  wrap = Fun.id;
}
