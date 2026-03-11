(** Bonus: Wait-free Atomic Snapshot (Gang-of-Six style)

    Each register stores:
    - current value
    - monotonic stamp
    - snapshot captured by the writer

    Scan uses repeated collects plus "helping":
    if a register changes twice during one scan, return the embedded snapshot
    from that register's latest write.
*)

type 'a cell = {
  value : 'a;
  stamp : int;
  snap : 'a array;
}

type 'a t = {
  regs : 'a cell Atomic.t array;
  n : int;
}

let size s = s.n

let check_index s i =
  if i < 0 || i >= s.n then invalid_arg "Bonus.update: index out of bounds"

let collect s =
  Array.init s.n (fun i -> Atomic.get s.regs.(i))

let create n init_value =
  if n <= 0 then invalid_arg "Bonus.create: n must be > 0";
  let init_snap = Array.make n init_value in
  let init_cell = { value = init_value; stamp = 0; snap = init_snap } in
  let regs = Array.init n (fun _ -> Atomic.make init_cell) in
  { regs; n }

let scan s =
  let moved = Array.make s.n false in
  let rec loop old =
    let newv = collect s in
    let rec find_change i =
      if i = s.n then None
      else if old.(i).stamp <> newv.(i).stamp then Some i
      else find_change (i + 1)
    in
    match find_change 0 with
    | None -> Array.init s.n (fun i -> newv.(i).value)
    | Some j ->
        if moved.(j) then Array.copy newv.(j).snap
        else (
          moved.(j) <- true;
          loop newv)
  in
  loop (collect s)

 
let update s idx value =
  check_index s idx;
  let prev = Atomic.get s.regs.(idx) in
  let snap = scan s in
  let next = { value; stamp = prev.stamp + 1; snap } in
  Atomic.set s.regs.(idx) next
