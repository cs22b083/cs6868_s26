type 'a state =
  | Empty of ('a option ref * Trigger.t) list
  | Filled of 'a

type 'a t = {
  mutex : Mutex.t;
  state : 'a state Atomic.t;
}

let create () = {
  mutex = Mutex.create ();
  state = Atomic.make (Empty []);
}

let fill t v =
  Mutex.lock t.mutex;
  match Atomic.get t.state with
  | Filled _ ->
      Mutex.unlock t.mutex;
      failwith "Ivar.fill: already filled"
  | Empty waiters ->
      Atomic.set t.state (Filled v);
      Mutex.unlock t.mutex;
      (* Write slots and signal triggers outside the lock — each signal
         may enqueue a continuation, acquiring the scheduler's queue lock. *)
      List.iter (fun (slot, tr) ->
        slot := Some v;
        ignore (Trigger.signal tr : bool)
      ) waiters

let read t =
  (* Fast path: no lock needed — once Filled, the state never changes. *)
  match Atomic.get t.state with
  | Filled v -> v
  | Empty _ ->
      (* Slow path: take the lock to add our trigger. *)
      Mutex.lock t.mutex;
      (* Double-check under lock (could have been filled in the meantime). *)
      (match Atomic.get t.state with
       | Filled v ->
           Mutex.unlock t.mutex;
           v
       | Empty waiters ->
           let slot = ref None in
           let tr = Trigger.create () in
           Atomic.set t.state (Empty ((slot, tr) :: waiters));
           Mutex.unlock t.mutex;
           Trigger.await tr;
           Option.get !slot)

let read_evt t : 'a Select.event = Select.Evt {
  try_complete = (fun () ->
    match Atomic.get t.state with
    | Filled v -> Some v
    | Empty _ -> None);
  offer = (fun slot trigger ->
    match Atomic.get t.state with
    | Empty waiters ->
        Atomic.set t.state (Empty ((slot, trigger) :: waiters))
    | Filled _ -> assert false);
  mutex = t.mutex;
  wrap = Fun.id;
}
