(** Atomic Snapshot Implementation using Double-Collect Algorithm *)

(** Type of atomic snapshot object *)
type 'a t = {
  registers : 'a ref array;       (* Array of non-atomic registers *)
  n : int;                         (* Number of registers *)
}

let create n init_value =
  if n <= 0 then invalid_arg "Snapshot.create ==> n must be > 0";
  let registers = Array.init n (fun _ -> ref init_value) in
  { registers; n }

let update snapshot idx value =
  if idx < 0 || idx >= snapshot.n then
    invalid_arg "Snapshot.update ==> index out of bounds";
  snapshot.registers.(idx) := value

(** Helper: collect all register values *)
(* Create a new array containing the current values of all atomic registers in the snapshot.*)
let collect snapshot =
  Array.init snapshot.n (fun i -> !(snapshot.registers.(i)))

(** Scan using double-collect algorithm *)
let scan snapshot =
  let rec loop () =
    let first = collect snapshot in
    let second = collect snapshot in
    if first = second then first else loop ()
  in
  loop ()

let size snapshot = snapshot.n
