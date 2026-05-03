(* Lecture 11: Gensym with Atomics
   =================================

   Classic problem: generate unique symbols in parallel.

   Step 1: A sequential gensym using a ref — works but not thread-safe.
   Step 2: Try to use it in fork_join2 — compiler rejects it!
   Step 3: Fix with Atomic — compiler accepts it.

   This is the OxCaml story: the type system catches the race *before*
   you run the program. No ThreadSanitizer needed.
*)

(* --- Step 1: Sequential gensym (ref-based) --- *)

let gensym_seq =
  let counter = ref 0 in
  fun () ->
    incr counter;
    Printf.sprintf "sym_%d" !counter

let () =
  Printf.printf "Sequential: %s, %s, %s\n"
    (gensym_seq ()) (gensym_seq ()) (gensym_seq ())

(* --- Step 2: This does NOT compile --- *)

(* The closure captures `counter : int ref`, which is uncontended
   mutable state. This makes gensym_seq nonportable.
   fork_join2 requires portable closures. Rejected at compile time.

   let bad_parallel par =
     let #(s1, s2) =
       Parallel.fork_join2 par
         (fun _par -> gensym_seq ())
         (fun _par -> gensym_seq ())
     in
     Printf.printf "%s %s\n" s1 s2

   Error: this function is nonportable but expected portable
*)

(* --- Step 3: Atomic gensym --- *)

let gensym_atomic =
  let counter = Atomic.make 0 in
  fun () ->
    let n = Atomic.fetch_and_add counter 1 in
    Printf.sprintf "sym_%d" (n + 1)

let parallel_gensym par =
  let #(s1, s2) =
    Parallel.fork_join2 par
      (fun _par -> gensym_atomic ())
      (fun _par -> gensym_atomic ())
  in
  Printf.printf "Parallel: %s, %s\n" s1 s2;
  assert (s1 <> s2)

(* --- Step 4: Generate many symbols in parallel, verify uniqueness --- *)

let parallel_gensym_many par n =
  let #(left, right) =
    Parallel.fork_join2 par
      (fun _par ->
        Array.init n (fun _ -> gensym_atomic ()))
      (fun _par ->
        Array.init n (fun _ -> gensym_atomic ()))
  in
  let all = Array.append left right in
  let sorted = Array.copy all in
  Array.sort String.compare sorted;
  let has_dup = ref false in
  for i = 0 to Array.length sorted - 2 do
    if sorted.(i) = sorted.(i + 1) then has_dup := true
  done;
  Printf.printf "Generated %d symbols, duplicates: %b\n"
    (Array.length all) !has_dup

let run_parallel ~f =
  let module Scheduler = Parallel_scheduler in
  let scheduler = Scheduler.create () in
  let result = Scheduler.parallel scheduler ~f in
  Scheduler.stop scheduler;
  result

let () =
  run_parallel ~f:parallel_gensym;
  run_parallel ~f:(fun par -> parallel_gensym_many par 10_000)
