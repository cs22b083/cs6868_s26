(* Lecture 11: Stack Allocation with local and stack_
   ==================================================

   In standard OCaml, all structured values (tuples, records, etc.)
   are heap-allocated and managed by the GC.

   OxCaml's locality mode lets us allocate on the stack instead:
   - `@ local` annotates a value that won't escape its scope
   - `stack_` forces stack allocation (compile error if it would escape)
   - The compiler infers locality where possible
*)

(* --- 1. Basic stack allocation with stack_ --- *)

let sum_pair () =
  let p = stack_ (3, 7) in
  let (a, b) = p in
  a + b

let () =
  Printf.printf "sum_pair: %d\n" (sum_pair ())

(* --- 2. Stack-allocated records --- *)

type point = { x : float; y : float }

let distance_from_origin () =
  let p = stack_ { x = 3.0; y = 4.0 } in
  Float.sqrt (p.x *. p.x +. p.y *. p.y)

let () =
  Printf.printf "distance: %f\n" (distance_from_origin ())

(* --- 3. Local parameters — promising not to capture --- *)

let process_point (p @ local) =
  p.x +. p.y

let () =
  let p = stack_ { x = 1.0; y = 2.0 } in
  Printf.printf "process_point: %f\n" (process_point p)

(* --- 4. Stack-allocated refs --- *)

let local_ref_sum () =
  let r = stack_ (ref 0) in
  for i = 1 to 10 do
    r := !r + i
  done;
  !r

let () =
  Printf.printf "local ref sum 1..10: %d\n" (local_ref_sum ())

(* --- 5. What you CANNOT do with local values --- *)

(* Uncomment to see the compiler error:

   let escape_local () =
     let p = stack_ { x = 1.0; y = 2.0 } in
     p  (* Error: this local value would escape its scope *)

   let store_local () =
     let p = stack_ { x = 1.0; y = 2.0 } in
     let r = ref p in  (* Error: cannot store local in global ref *)
     !r
*)

(* --- 6. Stack-allocated closures --- *)

let apply_locally f =
  let g = stack_ (fun x -> f (x + 1)) in
  (g 41) [@nontail]

let () =
  Printf.printf "apply_locally: %d\n" (apply_locally (fun x -> x))
