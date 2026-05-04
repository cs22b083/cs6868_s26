(* Lecture 11: Parallel Quicksort
   ================================

   Quicksort is naturally parallel: after partitioning, the two halves
   are independent and can be sorted in parallel.

   We use a simple slice abstraction (offset + length into an array)
   to avoid copying subarrays.
*)

(* --- Slice: a view into an array --- *)

module Slice = struct
  type 'a t = { array : 'a array; start : int; stop : int }

  let of_array arr = { array = arr; start = 0; stop = Array.length arr }

  let length s = s.stop - s.start

  let get s i = s.array.(s.start + i)

  let set s i v = s.array.(s.start + i) <- v

  let sub s ~i ~j = { array = s.array; start = s.start + i; stop = s.start + j }
end

let swap slice ~i ~j =
  let tmp = Slice.get slice i in
  Slice.set slice i (Slice.get slice j);
  Slice.set slice j tmp

let partition slice =
  let len = Slice.length slice in
  let pivot_idx = Random.int len in
  swap slice ~i:pivot_idx ~j:(len - 1);
  let pivot = Slice.get slice (len - 1) in
  let mutable store = 0 in
  for i = 0 to len - 2 do
    if Slice.get slice i <= pivot then begin
      swap slice ~i ~j:store;
      store <- store + 1
    end
  done;
  swap slice ~i:store ~j:(len - 1);
  store

(* --- Sequential quicksort --- *)

let rec quicksort_seq slice =
  if Slice.length slice > 1 then begin
    let p = partition slice in
    let len = Slice.length slice in
    quicksort_seq (Slice.sub slice ~i:0 ~j:p);
    quicksort_seq (Slice.sub slice ~i:p ~j:len)
  end

(* --- Parallel quicksort with cutoff --- *)

(* NOTE: A naive parallel version that captures mutable Slice.t values
   inside fork_join2 closures fails to compile:

     let #((), ()) =
       Parallel.fork_join2 par
         (fun par -> quicksort_par par left)
         (fun par -> quicksort_par par right)

   The closures must be "shareable", which makes the captured array
   "shared". But Array.get/set require "uncontended". The compiler
   correctly rejects this — even though the slices are disjoint,
   the type system cannot verify non-overlapping regions.

   The proper fix is to use Parallel.Arrays.Array.Slice.fork_join2
   which provides a safe API for splitting a mutable array into
   disjoint slices that can be processed in parallel. *)

let cutoff = 4096

let _quicksort_par par slice =
  let len = Slice.length slice in
  if len <= 1 then ()
  else if len <= cutoff then
    quicksort_seq slice
  else begin
    let p = partition slice in
    let _left = Slice.sub slice ~i:0 ~j:p in
    let _right = Slice.sub slice ~i:p ~j:len in
    ignore par;
    (* TODO: use Parallel.Arrays.Array.Slice.fork_join2 here *)
    quicksort_seq (Slice.sub slice ~i:0 ~j:p);
    quicksort_seq (Slice.sub slice ~i:p ~j:len)
  end

(* --- Verification --- *)

let is_sorted arr =
  let mutable ok = true in
  for i = 0 to Array.length arr - 2 do
    if arr.(i) > arr.(i + 1) then ok <- false
  done;
  ok

(* --- Benchmark --- *)

let time name f =
  let t0 = Unix.gettimeofday () in
  f ();
  let t1 = Unix.gettimeofday () in
  Printf.printf "%s: %.3fs\n" name (t1 -. t0)

let () =
  let n = 5_000_000 in
  Printf.printf "Sorting %d elements\n" n;

  let arr = Array.init n (fun _ -> Random.int n) in

  time "sequential quicksort" (fun () ->
    quicksort_seq (Slice.of_array arr));
  assert (is_sorted arr);
  Printf.printf "Sorted correctly: %b\n" (is_sorted arr)
