(** Manual tests for fiber-level Mutex / Condition / Semaphore / Barrier.

    Each test function returns [(ok, msg)] — [ok] is pass/fail, [msg]
    is a short description printed in the report.  Most tests run
    their fibers inside [Sched.run (fun () -> ...)]; remember that the
    scheduler is cooperative unicore, so you'll want [Sched.yield] to
    force interleavings. *)

open Golike_unicore_select

let passed = ref 0
let failed = ref 0

let report name ok msg =
  if ok then begin
    incr passed;
    Printf.printf "[ PASS ] %s — %s\n%!" name msg
  end else begin
    incr failed;
    Printf.printf "[ FAIL ] %s — %s\n%!" name msg
  end

let run_test name f =
  try
    let ok, msg = f () in
    report name ok msg
  with e ->
    incr failed;
    Printf.printf "[ EXN  ] %s — %s\n%!" name (Printexc.to_string e)

(** Test [try_lock] / [unlock] on a single mutex, sequentially. *)
let test_mutex_basic () = 
  let m = Mutex.create () in
  let a = Mutex.try_lock m in (* success *)
  let b = Mutex.try_lock m in (* fail *)
  Mutex.unlock m;
  let c = Mutex.try_lock m in (* success *)
  Mutex.unlock m;
  (a && (not b) && c, "try_lock/unlock basic behavior")

(** Test that blocked waiters are served in FIFO order. *)
let test_mutex_fifo () = 
  let m = Mutex.create () in
  let n = 6 in
  let order = ref [] in
  Sched.run (fun () ->
    Mutex.lock m; (* lock before to block when acquiring lock *)
    for i = 0 to n - 1 do
      Sched.fork (fun () ->
        Mutex.lock m;
        order := i :: !order;
        Mutex.unlock m)
    done;
    for _ = 1 to 8 do Sched.yield () done; (* randomness :  force scheduling interleavings  *)
    Mutex.unlock m;
    for _ = 1 to 20 do Sched.yield () done (* randomness :  force scheduling interleavings  *)
    );
  let got = List.rev !order in
  let want = List.init n Fun.id in
  (got = want, "blocked waiters served FIFO")

(** The [Bounded_buffer] module below is PROVIDED — a classic
    Mutex + two-condvar implementation of a bounded FIFO queue.
    Do not modify it; use it in [test_bounded_buffer]. *)

module Bounded_buffer = struct
  type 'a t = {
    m : Mutex.t;
    not_empty : Condition.t;
    not_full : Condition.t;
    buf : 'a Queue.t;
    capacity : int;
  }
  let create capacity = {
    m = Mutex.create ();
    not_empty = Condition.create ();
    not_full = Condition.create ();
    buf = Queue.create ();
    capacity;
  }
  let put b x =
    Mutex.lock b.m;
    while Queue.length b.buf = b.capacity do
      Condition.wait b.not_full b.m
    done;
    Queue.push x b.buf;
    Condition.signal b.not_empty;
    Mutex.unlock b.m
  let get b =
    Mutex.lock b.m;
    while Queue.is_empty b.buf do
      Condition.wait b.not_empty b.m
    done;
    let x = Queue.pop b.buf in
    Condition.signal b.not_full;
    Mutex.unlock b.m;
    x
end

(** Test bounded-buffer throughput — no items lost, no duplicates,
    under multiple concurrent producers and consumers. *)
let test_bounded_buffer () =  
  let producers = 4 in
  let per_producer = 40 in
  let consumers = 4 in
  let total = producers * per_producer in
  let b = Bounded_buffer.create 7 in
  let seen = Array.make total 0 in
  let bad_flag = ref false in
  Sched.run (fun () ->
    for _c = 0 to consumers - 1 do
      Sched.fork (fun () ->
        for _ = 1 to total / consumers do
          let v = Bounded_buffer.get b in
          if v < 0 || v >= total then bad_flag := true
          else seen.(v) <- seen.(v) + 1;
          Sched.yield ()
        done)
    done;
    for _p = 0 to producers - 1 do
      Sched.fork (fun () ->
        for i = 0 to per_producer - 1 do
          Bounded_buffer.put b (_p * per_producer + i);
          if i mod 9 = 0 then Sched.yield () (* random interleavings *)
        done)
    done);
  let all_once = Array.for_all (fun c -> c = 1) seen in (* check each occurs only once (no duplicates)*)
  (not !bad_flag && all_once, "bounded buffer: no loss/duplication under contention")

(** The [Rw_lock] module below is PROVIDED — writer-priority R/W lock.
    Do not modify it; use it in [test_readers_writers]. *)

module Rw_lock = struct
  type t = {
    m : Mutex.t;
    can_read : Condition.t;
    can_write : Condition.t;
    mutable readers : int;
    mutable writer : bool;
    mutable waiting_writers : int;
  }
  let create () = {
    m = Mutex.create ();
    can_read = Condition.create ();
    can_write = Condition.create ();
    readers = 0; writer = false; waiting_writers = 0;
  }
  let read_lock r =
    Mutex.lock r.m;
    while r.writer || r.waiting_writers > 0 do
      Condition.wait r.can_read r.m
    done;
    r.readers <- r.readers + 1;
    Mutex.unlock r.m
  let read_unlock r =
    Mutex.lock r.m;
    r.readers <- r.readers - 1;
    if r.readers = 0 then Condition.signal r.can_write;
    Mutex.unlock r.m
  let write_lock r =
    Mutex.lock r.m;
    r.waiting_writers <- r.waiting_writers + 1;
    while r.writer || r.readers > 0 do
      Condition.wait r.can_write r.m
    done;
    r.waiting_writers <- r.waiting_writers - 1;
    r.writer <- true;
    Mutex.unlock r.m
  let write_unlock r =
    Mutex.lock r.m;
    r.writer <- false;
    if r.waiting_writers > 0 then Condition.signal r.can_write
    else Condition.broadcast r.can_read;
    Mutex.unlock r.m
end

(** Test the R/W exclusion invariants: at most one writer,
    readers and writers never coexist. *)
let test_readers_writers () = 
  let rw = Rw_lock.create () in
  let active_readers = ref 0 in
  let active_writers = ref 0 in
  let violations = ref 0 in
  let readers = 5 in
  let writers = 3 in
  let rounds = 40 in
  Sched.run (fun () ->
    for _ = 1 to readers do
      Sched.fork (fun () ->
        for _ = 1 to rounds do
          Rw_lock.read_lock rw;
          if !active_writers > 0 then incr violations;
          incr active_readers;
          Sched.yield (); (* Forced interleavings *)
          decr active_readers;
          Rw_lock.read_unlock rw
        done)
    done;
    for _ = 1 to writers do
      Sched.fork (fun () ->
        for _ = 1 to rounds do
          Rw_lock.write_lock rw;
          if !active_writers > 0 || !active_readers > 0 then incr violations;
          incr active_writers;
          Sched.yield ();
          decr active_writers;
          Rw_lock.write_unlock rw
        done)
    done);
  (!violations = 0 && !active_readers = 0 && !active_writers = 0,
   "R/W invariants hold (no reader-writer overlap, <=1 writer)")

(** Test reusable N-party barrier: no fiber is more than one round
    ahead of any other across multiple barrier crossings. *)
let test_barrier () = 
  let n = 5 in
  let rounds = 8 in
  let b = Barrier.create n in
  let prog = Array.make n 0 in
  let chk = Mutex.create () in
  let bad = ref false in
  Sched.run (fun () ->
    for id = 0 to n - 1 do
      Sched.fork (fun () ->
        for _ = 1 to rounds do
          if id mod 2 = 0 then Sched.yield (); (* random forced interleavings *)
          Barrier.wait b;
          Mutex.lock chk;
          prog.(id) <- prog.(id) + 1;
          let mn = Array.fold_left min max_int prog in
          let mx = Array.fold_left max min_int prog in
          if mx - mn > 1 then bad := true;
          Mutex.unlock chk
        done)
    done);
  let all_done = Array.for_all (fun x -> x = rounds) prog in
  ((not !bad) && all_done, "reusable barrier keeps workers within one round")

(** Test that a semaphore with [k] permits never allows more than
    [k] fibers in the critical section simultaneously. *)
let test_semaphore () =
  let k = 3 in
  let workers = 15 in
  let loops = 20 in
  let s = Semaphore.create k in
  let m = Mutex.create () in (* for the shared vars *)
  let inside = ref 0 in (* keeping track of number of fibers in critical section *)
  let max_inside = ref 0 in
  let bad_flag = ref false in
  Sched.run (fun () ->
    for _ = 1 to workers do
      Sched.fork (fun () ->
        for _ = 1 to loops do
          Semaphore.acquire s;
          Mutex.lock m;
          incr inside;
          if !inside > k then bad_flag := true;
          if !inside > !max_inside then max_inside := !inside;
          Mutex.unlock m;

          Sched.yield (); (* Forced Interleavings *)

          Mutex.lock m;
          decr inside;
          Mutex.unlock m;
          Semaphore.release s
        done)
    done);
  ((not !bad_flag) && !max_inside <= k && !inside = 0,
   "semaphore enforces max-k concurrent entries")

(** Test that [Select.select] picks an already-free mutex in phase 1
    (the fast path). *)
let test_lock_evt_fastpath () = 
  let held = Mutex.create () in
  let free = Mutex.create () in
  let took_free = ref false in
  Sched.run (fun () ->
    Mutex.lock held;
    Select.select [Mutex.lock_evt held; Mutex.lock_evt free];
    took_free := not(Mutex.try_lock free); (* took_free should be false indicating 
                                              that free lock was taken *)
    Mutex.unlock free;
    Mutex.unlock held);
  ( !took_free , "select fast-path acquires already-free mutex")

(** Test [Select.select] over two held mutexes — it should block until
    one is unlocked, then take that case; stale waiter on the other
    mutex must be tolerated. *)
let test_lock_evt_blocking () = 
  let m1 = Mutex.create () in
  let m2 = Mutex.create () in
  let got_m2 = ref false in
  let got_m1 = ref false in 
  let m1_unlock_done = ref false in
  Sched.run (fun () ->
    Mutex.lock m1;
    Mutex.lock m2;

    Sched.fork (fun () ->
      Sched.yield ();
      Mutex.unlock m2);

    Sched.fork (fun () ->
      for _ = 1 to 6 do Sched.yield () done;
      Mutex.unlock m1;
      m1_unlock_done := true);

    Select.select [Mutex.lock_evt m1; Mutex.lock_evt m2];

    if not (Mutex.try_lock m2) then 
      got_m2 := true;      (* m2 is the one we acquired via select *)
      Mutex.unlock m2 ;

    if not (Mutex.try_lock m1) then 
      got_m1 := false; (* m1 was not acquired via select *)

    for _ = 1 to 10 do Sched.yield () done);
  (!got_m2 && not (!got_m1) && !m1_unlock_done, "lock_evt blocks, wakes on first unlock, stale waiter tolerated")


(** Test the load-balancer pattern from Lecture 10's [_scratch/test1.ml]:
    many clients race to claim any of several slot mutexes via
    [Select.select] over [lock_evt]. *)
let test_load_balancer () = 
  let slots_n = 4 in
  let clients = 50 in
  let slots = Array.init slots_n (fun _ -> Mutex.create ()) in
  let counts = Array.make slots_n 0 in
  let done_clients = ref 0 in
  let stats_m = Mutex.create () in
  Sched.run (fun () ->
    for _ = 1 to clients do
      Sched.fork (fun () ->
        (* choose any free slot *)

        let chosen_evt =
          Select.select [
            Select.wrap (fun () -> 0) (Mutex.lock_evt slots.(0)) ;
            Select.wrap (fun () -> 1) (Mutex.lock_evt slots.(1)) ;
            Select.wrap (fun () -> 2) (Mutex.lock_evt slots.(2)) ;
            Select.wrap (fun () -> 3) (Mutex.lock_evt slots.(3)) ;
          ]
        in
        Mutex.lock stats_m;
        counts.(chosen_evt) <- counts.(chosen_evt) + 1;
        incr done_clients;
        Mutex.unlock stats_m;

        Sched.yield ();
        Mutex.unlock slots.(chosen_evt))
    done);
  let total = Array.fold_left ( + ) 0 counts in
  let used_slots =
    Array.fold_left (fun acc c -> if c > 0 then acc + 1 else acc) 0 counts
  in
  (!done_clients = clients && total = clients && used_slots >= 2,
   "clients claim any free slot via select(lock_evt ...)")

(** Test that [Condition.wait] re-acquires the mutex before returning
    (POSIX semantics). *)
let test_wait_reacquires () = 
  let m = Mutex.create () in
  let c = Condition.create () in
  let reacquired = ref false in
  Sched.run (fun () ->
    Sched.fork (fun () ->
      Mutex.lock m;
      Condition.wait c m;
      reacquired := not (Mutex.try_lock m);  (* must already hold m *)
      Mutex.unlock m);

    Sched.fork (fun () ->
      Sched.yield ();
      Mutex.lock m;
      Condition.signal c;
      Mutex.unlock m));
  (!reacquired, "Condition.wait returns with mutex re-acquired")

let () =
  Printf.printf "=== Manual tests (fiber-level Mutex/Cond/Sem/Bar) ===\n%!";
  run_test "mutex_basic"           test_mutex_basic;
  run_test "mutex_fifo"            test_mutex_fifo;
  run_test "bounded_buffer"        test_bounded_buffer;
  run_test "readers_writers"       test_readers_writers;
  run_test "barrier"               test_barrier;
  run_test "semaphore"             test_semaphore;
  run_test "lock_evt_fastpath"     test_lock_evt_fastpath;
  run_test "lock_evt_blocking"     test_lock_evt_blocking;
  run_test "load_balancer"         test_load_balancer;
  run_test "wait_reacquires"       test_wait_reacquires;
  Printf.printf "\n%d passed, %d failed\n%!" !passed !failed;
  if !failed > 0 then exit 1
