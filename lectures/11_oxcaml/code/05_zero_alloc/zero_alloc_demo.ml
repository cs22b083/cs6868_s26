(* Lecture 11: Zero-Allocation Verification
   ==========================================

   [@zero_alloc] asks the compiler to statically verify that a function
   never allocates on the OCaml heap. Local (stack) allocations are OK.

   This is critical for:
   - Trading systems (predictable latency)
   - Network packet processing
   - Real-time audio/video
   - Any inner loop where GC pauses are unacceptable

   Variants:
   - [@zero_alloc]        — checked in all builds
   - [@zero_alloc opt]    — checked only at -O3
   - [@zero_alloc strict] — no allocations even on error paths
   - [@zero_alloc assume] — trust annotation, don't check
*)

(* --- 1. Simple zero-alloc arithmetic --- *)

let[@zero_alloc] [@inline never] fast_add x y = x + y

let[@zero_alloc] [@inline never] fast_multiply x y = x * y

let[@zero_alloc] [@inline never] dot_product_3d x1 y1 z1 x2 y2 z2 =
  x1 * x2 + y1 * y2 + z1 * z2

let () =
  Printf.printf "add: %d\n" (fast_add 3 4);
  Printf.printf "mul: %d\n" (fast_multiply 3 4);
  Printf.printf "dot: %d\n" (dot_product_3d 1 2 3 4 5 6)

(* --- 2. Zero-alloc with unboxed types --- *)

let[@zero_alloc] [@inline never] unboxed_distance
    (x1 : float#) (y1 : float#) (x2 : float#) (y2 : float#) : float# =
  let open Float_u in
  let dx = x2 - x1 in
  let dy = y2 - y1 in
  sqrt (dx * dx + dy * dy)

let () =
  let d = unboxed_distance #0.0 #0.0 #3.0 #4.0 in
  Printf.printf "unboxed distance: %f\n" (Float_u.to_float d)

(* --- 3. Zero-alloc with let mutable --- *)

let[@zero_alloc] [@inline never] array_sum (arr : int array) : int =
  let mutable acc = 0 in
  for i = 0 to Array.length arr - 1 do
    acc <- acc + Array.unsafe_get arr i
  done;
  acc

let[@zero_alloc] [@inline never] array_max (arr : int array) : int =
  let mutable best = Array.unsafe_get arr 0 in
  for i = 1 to Array.length arr - 1 do
    let v = Array.unsafe_get arr i in
    if v > best then best <- v
  done;
  best

let () =
  let arr = [| 3; 1; 4; 1; 5; 9; 2; 6; 5; 3 |] in
  Printf.printf "sum: %d\n" (array_sum arr);
  Printf.printf "max: %d\n" (array_max arr)

(* --- 4. What breaks [@zero_alloc] --- *)

(* Uncomment to see the compiler error:

   let[@zero_alloc] bad_alloc x =
     (x, x + 1)  (* Error: tuple allocation on heap *)

   let[@zero_alloc] bad_alloc2 x =
     [x; x + 1]  (* Error: list cons allocation on heap *)

   let[@zero_alloc] bad_alloc3 x =
     Printf.sprintf "%d" x  (* Error: string allocation *)
*)

(* --- 5. Zero-alloc with local (stack alloc is OK) --- *)

let[@zero_alloc] [@inline never] local_is_ok (x : int) (y : int) : int =
  let p @ local = stack_ (x, y) in
  let (a, b) = p in
  a + b

let () =
  Printf.printf "local alloc in zero_alloc: %d\n" (local_is_ok 10 20)

(* --- 6. Zero-alloc inner loop with unboxed return --- *)

let[@zero_alloc] [@inline never] find_min_max (arr : int array) : #(int * int) =
  let mutable lo = Array.unsafe_get arr 0 in
  let mutable hi = Array.unsafe_get arr 0 in
  for i = 1 to Array.length arr - 1 do
    let v = Array.unsafe_get arr i in
    if v < lo then lo <- v;
    if v > hi then hi <- v
  done;
  #(lo, hi)

let () =
  let arr = [| 3; 1; 4; 1; 5; 9; 2; 6; 5; 3 |] in
  let #(lo, hi) = find_min_max arr in
  Printf.printf "min=%d max=%d\n" lo hi
