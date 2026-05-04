(* Lecture 11: Parallel Map-Reduce
   =================================

   A common pattern: split work, process halves in parallel,
   combine results. The mode system ensures safety.

   We use Iarray (immutable arrays) so the data can be freely
   shared across fork_join2 branches without contention issues.
*)

open! Base

(* --- Parallel reduce on an immutable array --- *)

let rec parallel_reduce par (arr : int Iarray.t) lo hi f combine =
  if hi - lo <= 64 then begin
    let mutable acc = f (Iarray.get arr lo) in
    for i = lo + 1 to hi - 1 do
      acc <- combine acc (f (Iarray.get arr i))
    done;
    acc
  end else
    let mid = lo + (hi - lo) / 2 in
    let #(left, right) =
      Parallel.fork_join2 par
        (fun par -> parallel_reduce par arr lo mid f combine)
        (fun par -> parallel_reduce par arr mid hi f combine)
    in
    combine left right

(* --- Demo --- *)

let run_parallel ~f =
  let module Scheduler = Parallel_scheduler in
  let scheduler = Scheduler.create () in
  let result = Scheduler.parallel scheduler ~f in
  Scheduler.stop scheduler;
  result

let () =
  let n = 10_000_000 in
  let arr = Iarray.init n ~f:Fn.id in

  let t0 = Unix.gettimeofday () in
  let mutable seq_sum = 0 in
  for i = 0 to n - 1 do
    seq_sum <- seq_sum + Iarray.get arr i
  done;
  let t1 = Unix.gettimeofday () in
  Stdio.printf "sequential sum: %d (%.3fs)\n" seq_sum (t1 -. t0);

  let t0 = Unix.gettimeofday () in
  let par_sum = run_parallel ~f:(fun par ->
    parallel_reduce par arr 0 n Fn.id ( + ))
  in
  let t1 = Unix.gettimeofday () in
  Stdio.printf "parallel sum:   %d (%.3fs)\n" par_sum (t1 -. t0)
