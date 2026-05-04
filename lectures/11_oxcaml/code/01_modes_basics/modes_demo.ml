(* Lecture 11: OxCaml Modes Basics
   ================================
   Modes describe *how* a value can be used, orthogonal to its type.

   Key axes:
   - Locality:    local (stack) vs global (heap)
   - Portability: portable (can cross domains) vs nonportable
   - Contention:  uncontended vs shared vs contended
   - Uniqueness:  unique (single ref) vs aliased
   - Linearity:   once (single call) vs many
*)

(* --- 1. Locality: local vs global --- *)

(* A function that takes a local parameter.
   The caller promises not to let the argument escape. *)
let use_locally (x @ local) =
  x + 1

(* A function that returns a local value using exclave_ *)
let make_pair (a : int) (b : int) : (int * int) @ local =
  exclave_ (a, b)

let () =
  let result = use_locally 42 in
  Printf.printf "use_locally 42 = %d\n" result;
  let _p @ local = make_pair 1 2 in
  Printf.printf "Local pair created on stack\n"

(* --- 2. Mode crossing --- *)

(* Some types "mode cross" — they can be freely used at any mode.
   For example, int is immediate and crosses all axes. *)
let demonstrate_crossing () =
  let x : int = 42 in
  let _ @ local = x in
  let _y : int = x in
  Printf.printf "int crosses modes freely: %d\n" x

let () = demonstrate_crossing ()

(* --- 3. Closures and modes --- *)

(* A pure function (no mutable captures) is portable *)
let _pure_add (x : int) (y : int) = x + y

(* A function capturing a mutable ref is NOT portable —
   it cannot safely cross domain boundaries. *)
let make_counter () =
  let r = ref 0 in
  fun () ->
    incr r;
    !r

(* The counter closure captures a ref, making it nonportable.
   Try annotating it as portable and watch the compiler reject it:

   let bad : (unit -> int) @ portable = make_counter ()
   ^^^^^^ Error: this value is nonportable
*)

let () =
  let counter = make_counter () in
  Printf.printf "Counter: %d, %d, %d\n"
    (counter ()) (counter ()) (counter ())

(* --- 4. Uniqueness --- *)

(* Unique values have exactly one reference.
   This enables safe resource management patterns. *)
let consume_unique (x @ unique) =
  Printf.printf "Consumed unique value: %d\n" x

let () =
  let v @ unique = 99 in
  consume_unique v

(* --- 5. Linearity: once vs many --- *)

(* A 'once' function can be called at most one time.
   Useful when the closure captures a unique value. *)
let make_once_fn () : (unit -> int) @ once =
  let v @ unique = 42 in
  fun () -> v

let () =
  let f = make_once_fn () in
  let result = f () in
  Printf.printf "Once function returned: %d\n" result
