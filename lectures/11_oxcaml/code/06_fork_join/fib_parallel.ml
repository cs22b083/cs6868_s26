(* Lecture 11: Fork-Join Parallelism
   ===================================

   Parallel.fork_join2 par f g:
   - Runs f and g potentially in parallel
   - f and g must be portable (no captured mutable state)
   - Returns an unboxed tuple #(result_f, result_g)
   - Work-stealing scheduler distributes tasks across domains

   The par : Parallel.t value is a capability token. It is
   passed to every parallel function, threading the scheduler.
*)

(* --- Sequential baseline --- *)

let rec fib_seq n =
  if n <= 1 then n
  else fib_seq (n - 1) + fib_seq (n - 2)

(* --- Naive parallel fib --- *)

let rec fib_par par n =
  if n <= 1 then n
  else
    let #(a, b) =
      Parallel.fork_join2 par
        (fun par -> fib_par par (n - 1))
        (fun par -> fib_par par (n - 2))
    in
    a + b

(* --- Parallel fib with cutoff --- *)

let rec fib_cutoff par n =
  if n <= 20 then fib_seq n
  else
    let #(a, b) =
      Parallel.fork_join2 par
        (fun par -> fib_cutoff par (n - 1))
        (fun par -> fib_cutoff par (n - 2))
    in
    a + b

(* --- Benchmark --- *)

let time name f =
  let t0 = Unix.gettimeofday () in
  let result = f () in
  let t1 = Unix.gettimeofday () in
  Printf.printf "%s: %d (%.3fs)\n" name result (t1 -. t0)

let run_parallel ~f =
  let module Scheduler = Parallel_scheduler in
  let scheduler = Scheduler.create () in
  let result = Scheduler.parallel scheduler ~f in
  Scheduler.stop scheduler;
  result

let n = 35

let () =
  time "sequential" (fun () -> fib_seq n);
  time "parallel (naive)" (fun () ->
    run_parallel ~f:(fun par -> fib_par par n));
  time "parallel (cutoff=20)" (fun () ->
    run_parallel ~f:(fun par -> fib_cutoff par n))
