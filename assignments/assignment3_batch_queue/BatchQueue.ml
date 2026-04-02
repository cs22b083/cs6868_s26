(** Batch Bounded Blocking Queue

    A bounded blocking queue where enqueue and dequeue operate on
    batches of elements atomically, with strict FIFO fairness and
    head-of-line blocking for both enqueue and dequeue waiters.

    Uses a single mutex with per-waiter condition variables. *)

(** A blocked enqueuer waiting for enough free space. *)
type 'a enq_waiter = {
  items : 'a array;       (** The batch of items this thread wants to enqueue *)
  cond : Condition.t;     (** Private condition variable — signaled when this
                              waiter reaches the head and space may be available *)
}

(** A blocked dequeuer waiting for enough items. *)
type 'a deq_waiter = {
  amount : int;           (** Number of items this thread wants to dequeue *)
  cond : Condition.t;     (** Private condition variable — signaled when this
                              waiter reaches the head and items may be available *)
}

type 'a t = {
  mutex : Mutex.t;
  buffer : 'a Queue.t;                   (** Items currently in the inbuilt queue *)
  capacity : int;
  enq_waiters : 'a enq_waiter Queue.t;   (** FIFO queue of blocked enqueuers *)
  deq_waiters : 'a deq_waiter Queue.t;   (** FIFO queue of blocked dequeuers *)
}

(** [create capacity] initializes a new queue. Validate capacity, then
    initialize all fields of the ['a t] record. *)
let create capacity =
  if capacity <= 0 then invalid_arg "BatchQueue: capacity must be positive that is > 0";
  {
    mutex = Mutex.create ();
    buffer = Queue.create ();
    capacity;
    enq_waiters = Queue.create ();
    deq_waiters = Queue.create ();
  }

let validate_enq_count q n =
  if n <= 0 then
    invalid_arg "BatchQueue: batch size must be positive";
  if n > q.capacity then
    invalid_arg "BatchQueue: batch size exceeds capacity"

let validate_deq_count q n =
  if n <= 0 then
    invalid_arg "BatchQueue: dequeue count must be positive";
  if n > q.capacity then
    invalid_arg "BatchQueue: dequeue count exceeds capacity"

let free_space q = q.capacity - Queue.length q.buffer

(** [notify q] checks the head of each waiter queue and signals it if
    its request can now be satisfied. Call after every enqueue or dequeue. *)
let notify q =
  if not (Queue.is_empty q.enq_waiters) then (
    let w = Queue.peek q.enq_waiters in
    if Array.length w.items <= free_space q then Condition.signal w.cond
  );
  if not (Queue.is_empty q.deq_waiters) then (
    let w = Queue.peek q.deq_waiters in
    if w.amount <= Queue.length q.buffer then Condition.signal w.cond
  )

(** [enq q items] atomically enqueues all items. Algorithm:
    1. Validate and lock the mutex (use [Fun.protect] for safe unlock).
    2. If [enq_waiters] is non-empty OR not enough free space:
       - Create a waiter, push it to [enq_waiters], and loop on
         [Condition.wait] until this waiter is at the head of
         [enq_waiters] AND there is enough space.
       - Pop self from [enq_waiters].
    3. Push all items into [buffer].
    4. Call [notify]. *)
let enq q items =
  let n = Array.length items in
  validate_enq_count q n; (* return Invalid_argument if invalid argument*)
  Mutex.lock q.mutex;
  Fun.protect
    ~finally:(fun () -> Mutex.unlock q.mutex)
    (fun () ->
       if (not (Queue.is_empty q.enq_waiters)) || n > free_space q then ( (* If [enq_waiters] is non-empty OR not enough free space *)
         let waiter = { items; cond = Condition.create () } in
         Queue.push waiter q.enq_waiters;
         while
           Queue.peek q.enq_waiters != waiter
           || Array.length waiter.items > free_space q
         do
           Condition.wait waiter.cond q.mutex
         done;
         ignore (Queue.pop q.enq_waiters)
       );
       Array.iter (fun x -> Queue.push x q.buffer) items; (* finally push it in the queue *)
       notify q) (* Call notify *)

(** [deq q n] atomically dequeues [n] items. Symmetric to [enq]:
    wait on [deq_waiters] until at head AND enough items available. *)
    (* Similar to enq*)
let deq q n =
  validate_deq_count q n;
  Mutex.lock q.mutex;
  Fun.protect
    ~finally:(fun () -> Mutex.unlock q.mutex)
    (fun () ->
       if (not (Queue.is_empty q.deq_waiters)) || n > Queue.length q.buffer then (
         let waiter = { amount = n; cond = Condition.create () } in
         Queue.push waiter q.deq_waiters;
         while
           Queue.peek q.deq_waiters != waiter
           || waiter.amount > Queue.length q.buffer
         do
           Condition.wait waiter.cond q.mutex
         done;
         ignore (Queue.pop q.deq_waiters)
       );
       let out = Array.init n (fun _ -> Queue.pop q.buffer) in
       notify q;
       out)

(** [try_enq q items] non-blocking enqueue. If no enqueuers are waiting
    ahead AND enough free space, enqueue and return [true]. Otherwise
    return [false] immediately (do not create a waiter). *)
let try_enq q items =
  let n = Array.length items in
  validate_enq_count q n;
  Mutex.lock q.mutex;
  Fun.protect
    ~finally:(fun () -> Mutex.unlock q.mutex)
    (fun () ->
       if (not (Queue.is_empty q.enq_waiters)) || n > free_space q then
         false
       else (
         Array.iter (fun x -> Queue.push x q.buffer) items;
         notify q;
         true
       ))

(** [try_deq q n] non-blocking dequeue. If no dequeuers are waiting
    ahead AND enough items, dequeue and return [Some items]. Otherwise
    return [None] immediately (do not create a waiter). *)
let try_deq q n =
  validate_deq_count q n;
  Mutex.lock q.mutex;
  Fun.protect
    ~finally:(fun () -> Mutex.unlock q.mutex)
    (fun () ->
       if (not (Queue.is_empty q.deq_waiters)) || n > Queue.length q.buffer then
         None
       else (
         let out = Array.init n (fun _ -> Queue.pop q.buffer) in
         notify q;
         Some out
       ))

let size q = (* locks for data race free*)
  Mutex.lock q.mutex;
  Fun.protect
    ~finally:(fun () -> Mutex.unlock q.mutex)
    (fun () -> Queue.length q.buffer)

let capacity q = q.capacity
