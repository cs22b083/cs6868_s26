(* Lecture 11: Capsules — Safe Shared Mutable State
   ==================================================

   Atomics work for simple values (counters, flags). But what about
   sharing a hash table, a tree, or any complex mutable structure
   across parallel tasks?

   Capsules are OxCaml's answer: a branded container for mutable state
   with compile-time access control.

   Key concepts:
   - Capsule.Data.t     — the encapsulated data (branded with type 'k)
   - Capsule.Mutex.t    — a mutex protecting the capsule
   - Capsule.Access.t   — proof that you hold the lock
   - With_mutex.t       — convenient combo of data + mutex

   Why not just use regular mutexes?
   → Regular mutexes are a runtime convention ("always lock before access").
     Nothing stops you from forgetting. Capsules make this a compile-time
     guarantee: you literally cannot access the data without the lock.
*)

open Await

(* --- 1. With_mutex: the convenient capsule pattern --- *)

let demo_with_mutex par =
  let protected = Await_capsule.With_mutex.create (fun () -> ref 0) in
  let n = 10_000 in
  let #((), ()) =
    Parallel.fork_join2 par
      (fun _par ->
        let w = Await_blocking.await Terminator.never in
        for _ = 1 to n do
          Await_capsule.With_mutex.iter w protected
            ~f:(fun r -> r := !r + 1)
        done)
      (fun _par ->
        let w = Await_blocking.await Terminator.never in
        for _ = 1 to n do
          Await_capsule.With_mutex.iter w protected
            ~f:(fun r -> r := !r + 1)
        done)
  in
  let w = Await_blocking.await Terminator.never in
  let result =
    Await_capsule.With_mutex.with_lock w protected
      ~f:(fun r -> !r)
  in
  Printf.printf "with_mutex counter: %d (expected %d)\n" result (2 * n);
  assert (result = 2 * n)

(* --- 2. Low-level capsule: Mutex + Data + Access --- *)

let demo_low_level par =
  let (P mutex) = Await_capsule.Mutex.create () in
  let data = Capsule.Data.create (fun () -> ref 0) in
  let n = 5_000 in
  let #((), ()) =
    Parallel.fork_join2 par
      (fun _par ->
        let w = Await_blocking.await Terminator.never in
        for _ = 1 to n do
          Await_capsule.Mutex.with_lock w mutex
            ~f:(fun access ->
              let r = Capsule.Data.unwrap data ~access in
              r := !r + 1)
        done)
      (fun _par ->
        let w = Await_blocking.await Terminator.never in
        for _ = 1 to n do
          Await_capsule.Mutex.with_lock w mutex
            ~f:(fun access ->
              let r = Capsule.Data.unwrap data ~access in
              r := !r + 1)
        done)
  in
  let w = Await_blocking.await Terminator.never in
  let result =
    Await_capsule.Mutex.with_lock w mutex
      ~f:(fun access ->
        let r = Capsule.Data.unwrap data ~access in
        !r)
  in
  Printf.printf "low-level capsule counter: %d (expected %d)\n" result (2 * n)

(* --- 3. With_mutex accumulator (shared list) --- *)

let demo_accumulator par =
  let protected = Await_capsule.With_mutex.create (fun () -> ref []) in
  let #((), ()) =
    Parallel.fork_join2 par
      (fun _par ->
        let w = Await_blocking.await Terminator.never in
        for i = 0 to 9 do
          Await_capsule.With_mutex.iter w protected
            ~f:(fun r -> r := Printf.sprintf "left_%d" i :: !r)
        done)
      (fun _par ->
        let w = Await_blocking.await Terminator.never in
        for i = 0 to 9 do
          Await_capsule.With_mutex.iter w protected
            ~f:(fun r -> r := Printf.sprintf "right_%d" i :: !r)
        done)
  in
  let w = Await_blocking.await Terminator.never in
  let items =
    Await_capsule.With_mutex.with_lock w protected
      ~f:(fun r -> List.rev !r)
  in
  Printf.printf "accumulator has %d items\n" (List.length items)

(* --- Runner --- *)

let run_parallel ~f =
  let module Scheduler = Parallel_scheduler in
  let scheduler = Scheduler.create () in
  let result = Scheduler.parallel scheduler ~f in
  Scheduler.stop scheduler;
  result

let () =
  run_parallel ~f:demo_with_mutex;
  run_parallel ~f:demo_low_level;
  run_parallel ~f:demo_accumulator
