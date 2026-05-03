(* Lecture 11: Local Regions and exclave_
   =======================================

   A local region is the stack frame of a function.
   Values allocated with stack_ live in the current region.

   exclave_ lets a function allocate in the *caller's* region,
   effectively returning a stack-allocated value.
*)

(* --- 1. exclave_: returning local values --- *)

type point = { x : float; y : float }

let make_point (x : float) (y : float) : point @ local =
  exclave_ { x; y }

let () =
  let p @ local = make_point 3.0 4.0 in
  Printf.printf "point: (%f, %f)\n" p.x p.y

(* --- 2. Chaining local returns --- *)

let add_points (a @ local) (b @ local) : point @ local =
  exclave_ { x = a.x +. b.x; y = a.y +. b.y }

let () =
  let a @ local = make_point 1.0 2.0 in
  let b @ local = make_point 3.0 4.0 in
  let c @ local = add_points a b in
  Printf.printf "sum: (%f, %f)\n" c.x c.y

(* --- 3. Practical pattern: temporary accumulator on the stack --- *)

let sum_array (arr : int array) =
  let acc = stack_ (ref 0) in
  for i = 0 to Array.length arr - 1 do
    acc := !acc + arr.(i)
  done;
  !acc

let () =
  Printf.printf "sum: %d\n" (sum_array [|1; 2; 3; 4; 5|])
