(* Lecture 11: Parallel Dot Product — Putting It All Together
   ============================================================

   Combines:
   - let mutable for zero-alloc inner loops
   - Iarray (immutable arrays) for safe sharing across parallel branches
   - Fork-join for parallelism
   - Mode system for data-race freedom
*)

open! Base

(* --- Sequential dot product --- *)

let dot_seq (a : float Iarray.t) (b : float Iarray.t) lo hi : float =
  let mutable acc = 0.0 in
  for i = lo to hi - 1 do
    acc <- acc +. Iarray.get a i *. Iarray.get b i
  done;
  acc

(* --- Parallel dot product --- *)

let chunk_size = 8192

let rec dot_par par (a : float Iarray.t) (b : float Iarray.t) lo hi =
  if hi - lo <= chunk_size then
    dot_seq a b lo hi
  else
    let mid = lo + (hi - lo) / 2 in
    let #(left, right) =
      Parallel.fork_join2 par
        (fun par -> dot_par par a b lo mid)
        (fun par -> dot_par par a b mid hi)
    in
    left +. right

(* --- Benchmark --- *)

let time name f =
  let t0 = Unix.gettimeofday () in
  let result = f () in
  let t1 = Unix.gettimeofday () in
  Stdio.printf "%s: %.4fs\n" name (t1 -. t0);
  result

let run_parallel ~f =
  let module Scheduler = Parallel_scheduler in
  let scheduler = Scheduler.create () in
  let result = Scheduler.parallel scheduler ~f in
  Scheduler.stop scheduler;
  result

let () =
  let n = 10_000_000 in
  Stdio.printf "Dot product of %d-element vectors\n" n;

  let a = Iarray.init n ~f:(fun i -> Float.of_int i /. Float.of_int n) in
  let b = Iarray.init n ~f:(fun i -> Float.of_int (n - i) /. Float.of_int n) in

  let r1 = time "sequential" (fun () -> dot_seq a b 0 n) in
  let r2 = time "parallel" (fun () ->
    run_parallel ~f:(fun par -> dot_par par a b 0 n)) in
  Stdio.printf "results match: %b (seq=%.6f par=%.6f)\n"
    Float.(abs (r1 - r2) < 1e-6) r1 r2
