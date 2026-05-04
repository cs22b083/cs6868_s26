(* Lecture 11: Unboxed Types
   =========================

   Standard OCaml boxes all structured values: a float is a pointer
   to a 2-word heap object. This costs allocation + indirection.

   OxCaml provides unboxed types that live in registers or directly
   in memory, with no heap allocation or pointer indirection:

   - float#   : unboxed 64-bit float (literal: #3.14)
   - int32#   : unboxed 32-bit int   (literal: #42l)
   - int64#   : unboxed 64-bit int   (literal: #42L)
   - #{ ... } : unboxed records
   - #( ... ) : unboxed tuples
*)

(* --- 1. Unboxed float literals and arithmetic --- *)

let unboxed_arithmetic () =
  let open Float_u in
  let x : float# = #3.14 in
  let y : float# = #2.71 in
  let sum = x + y in
  let prod = x * y in
  Printf.printf "unboxed: %f + %f = %f\n"
    (to_float x) (to_float y) (to_float sum);
  Printf.printf "unboxed: %f * %f = %f\n"
    (to_float x) (to_float y) (to_float prod)

let () = unboxed_arithmetic ()

(* --- 2. Unboxed records --- *)

type point = #{ x : float#; y : float# }

let make_point (x : float) (y : float) : point =
  #{ x = Float_u.of_float x; y = Float_u.of_float y }

let distance (a : point) (b : point) : float# =
  let open Float_u in
  let dx = b.#x - a.#x in
  let dy = b.#y - a.#y in
  sqrt (dx * dx + dy * dy)

let () =
  let p1 = make_point 0.0 0.0 in
  let p2 = make_point 3.0 4.0 in
  let d = distance p1 p2 in
  Printf.printf "distance: %f\n" (Float_u.to_float d)

(* --- 3. Unboxed tuples --- *)

let divmod (a : int) (b : int) : #(int * int) =
  #(a / b, a mod b)

let () =
  let #(q, r) = divmod 17 5 in
  Printf.printf "17 / 5 = %d remainder %d\n" q r

(* --- 4. Unboxed int types --- *)

let int32_demo () =
  let open Int32_u in
  let a : int32# = #100l in
  let b : int32# = #200l in
  let sum = a + b in
  Printf.printf "int32#: %ld + %ld = %ld\n"
    (to_int32 a) (to_int32 b) (to_int32 sum)

let int64_demo () =
  let open Int64_u in
  let a : int64# = #1_000_000_000L in
  let b : int64# = #2_000_000_000L in
  let sum = a + b in
  Printf.printf "int64#: %Ld + %Ld = %Ld\n"
    (to_int64 a) (to_int64 b) (to_int64 sum)

let () =
  int32_demo ();
  int64_demo ()

(* --- 5. let mutable — mutable locals without ref cells --- *)

let sum_array (arr : int array) : int =
  let mutable acc = 0 in
  for i = 0 to Array.length arr - 1 do
    acc <- acc + arr.(i)
  done;
  acc

let () =
  let arr = [| 1; 2; 3; 4; 5; 6; 7; 8; 9; 10 |] in
  Printf.printf "sum with let mutable: %d\n" (sum_array arr)

(* --- 6. Comparison: boxed vs unboxed in a tight loop --- *)

let boxed_sum n =
  let acc = ref 0.0 in
  for i = 1 to n do
    acc := !acc +. Float.of_int i
  done;
  !acc

let unboxed_sum n =
  let open Float_u in
  let mutable acc : float# = #0.0 in
  for i = 1 to n do
    acc <- acc + of_float (Float.of_int i)
  done;
  to_float acc

let () =
  let n = 1_000_000 in
  let t0 = Sys.time () in
  let r1 = boxed_sum n in
  let t1 = Sys.time () in
  let r2 = unboxed_sum n in
  let t2 = Sys.time () in
  Printf.printf "boxed sum:   %f (%.4fs)\n" r1 (t1 -. t0);
  Printf.printf "unboxed sum: %f (%.4fs)\n" r2 (t2 -. t1)
