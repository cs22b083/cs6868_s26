(* path_length annotated with [@zero_alloc] — this file is rejected
   by the compiler at -O3, demonstrating that boxed floats prevent
   the "no heap traffic" claim from holding for path_length.

   Part 6 introduces unboxed floats (float#) which fix this. *)

type point = { x : float; y : float }

let distance (a @ local) (b @ local) =
  let dx = a.x -. b.x in
  let dy = a.y -. b.y in
  Float.sqrt (dx *. dx +. dy *. dy)

let[@zero_alloc] [@inline never] rec path_length
    (poly : point list @ local) : float =
  match poly with
  | a :: (b :: _ as rest) -> distance a b +. path_length rest
  | _ -> 0.0

(* Error: Annotation check for zero_alloc failed on function path_length.
   Error: allocation of 16 bytes for float. *)
