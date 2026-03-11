(** Bonus: Wait-free Atomic Snapshot (Gang-of-Six style)

    Each register stores:
    - current value
    - monotonic stamp
    - snapshot captured by the writer

    Scan uses repeated collects plus "helping"/"borrowing":
    - scan succesful i.e no change then DONE.
    - if a register changes twice during one scan, return the embedded snapshot
    from that register's latest write.
*)
(* instead of directly using int or other types use cell for the type*)
type 'a cell = {
  value : 'a; (* same as value of the index originally *)
  stamp : int;
  snap : 'a array;
}

type 'a t = {
  regs : 'a cell Atomic.t array;
  n : int;
}

let size s = s.n


let collect s =
  Array.init s.n (fun i -> Atomic.get s.regs.(i))

let create n init_value =
  if n <= 0 then invalid_arg "Bonus.create: n must be > 0";
  let init_snap = Array.make n init_value in
  let init_cell = { value = init_value; stamp = 0; snap = init_snap } in
  let regs = Array.init n (fun _ -> Atomic.make init_cell) in
  { regs; n }


(* Main change is here *)
  let scan s =
  let changed = Array.make s.n false in
  let rec loop old =
    let newv = collect s in
    let rec find_change i =
      if i = s.n then None
      else if old.(i).stamp <> newv.(i).stamp then Some i
      else find_change (i + 1)
    in
    match find_change 0 with
    | None -> Array.init s.n (fun i -> newv.(i).value)
    (*If the reader sees process P update its register twice during the reader's looping collects, it means P has completely finished a full Update cycle after the reader started.
    Because an Update requires the writer to take its own snapshot, the reader knows that P's snapshot was taken entirely within the time window of the reader's current Scan. 
    The reader can simply stop collecting and borrow P's snapshot, returning it as its own. 
    This guarantees the Scan finishes in at most O(n^2) reads.*)
    | Some j ->
        if changed.(j) then Array.copy newv.(j).snap
        else (
          changed.(j) <- true;
          loop newv)
  in
  loop (collect s)

 
let update s idx value =
  if idx < 0 || idx >= s.n then invalid_arg "Bonus.update: index out of bounds";
  let prev = Atomic.get s.regs.(idx) in
  let snap = scan s in
  let next = { value; stamp = prev.stamp + 1; snap } in
  Atomic.set s.regs.(idx) next
