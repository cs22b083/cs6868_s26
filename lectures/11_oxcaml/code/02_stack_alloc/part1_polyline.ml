(* Lecture 11, Part 1: Safe Stack Allocation
   Polyline running example. *)

(* Locality: local vs global. *)

let use_locally (r @ local) = !r + 1

let _test_use_locally () =
  let r = ref 41 in
  use_locally r

(* Stack allocation with stack_. *)

type point = { x : float; y : float }

let distance (a @ local) (b @ local) =
  let dx = a.x -. b.x in
  let dy = a.y -. b.y in
  Float.sqrt (dx *. dx +. dy *. dy)

let test_distance () =
  let a = stack_ { x = 0.0; y = 0.0 } in
  let b = stack_ { x = 3.0; y = 4.0 } in
  let d = distance a b in
  d

(* Returning local values with exclave_. *)

let midpoint (a @ local) (b @ local) : point @ local =
  exclave_ { x = (a.x +. b.x) /. 2.0; y = (a.y +. b.y) /. 2.0 }

let translate (p @ local) (dx : float) (dy : float) : point @ local =
  exclave_ { x = p.x +. dx; y = p.y +. dy }

(* Mode crossing: float results escape freely. *)

let triangle_perimeter (a @ local) (b @ local) (c @ local) : float =
  distance a b +. distance b c +. distance c a

let test_perimeter () =
  let a = stack_ { x = 0.0; y = 0.0 } in
  let b = stack_ { x = 3.0; y = 0.0 } in
  let c = stack_ { x = 3.0; y = 4.0 } in
  let p = triangle_perimeter a b c in
  p

(* Local lists: traversal and map-style construction.

   path_length is NOT zero-alloc: each [distance a b] returns a boxed
   float (16 bytes), and [+.] allocates another box for the running sum.
   See part1_path_length_alloc_fail.ml for the [@zero_alloc] failure.
   Part 6 fixes this with unboxed floats (float#). *)

let rec path_length (poly : point list @ local) : float =
  match poly with
  | a :: (b :: _ as rest) -> distance a b +. path_length rest
  | _ -> 0.0

(* translate_polyline IS zero-alloc: every cons and every translated
   point lives in the caller's local region (exclave_), no heap traffic. *)

let[@zero_alloc] [@inline never] rec translate_polyline
    (poly : point list @ local) dx dy : point list @ local =
  match poly with
  | [] -> exclave_ []
  | p :: rest ->
      exclave_ (translate p dx dy :: translate_polyline rest dx dy)

(* Part 6 preview: the same path_length using float# (unboxed float)
   passes [@zero_alloc] verification at -O3. We don't explain float#
   here — just observe that the boxed-float allocation goes away when
   the floats live in registers instead of on the heap. *)

let[@zero_alloc] [@inline never] distance_u
    (a @ local) (b @ local) : float# =
  let open Float_u in
  let dx = of_float a.x - of_float b.x in
  let dy = of_float a.y - of_float b.y in
  sqrt (dx * dx + dy * dy)

let[@zero_alloc] [@inline never] rec path_length_u
    (poly : point list @ local) (acc : float#) : float# =
  let open Float_u in
  match poly with
  | a :: (b :: _ as rest) -> path_length_u rest (acc + distance_u a b)
  | _ -> acc
