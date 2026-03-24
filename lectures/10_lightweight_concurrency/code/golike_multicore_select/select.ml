(** CML-style events for composable synchronous communication (multicore-safe).

    Each event carries the sync object's [mutex] so that {!select} can
    acquire all involved locks in a deterministic order (by mutex address)
    before scanning or offering.  A single shared {!Trigger.t} is used
    across all cases: the first counterpart to signal it wins; others
    see {!Trigger.signal} return [false] and skip the stale waiter. *)

type 'b event = Evt : {
  try_complete : unit -> 'a option;
  offer : 'a option ref -> Trigger.t -> unit;
  mutex : Mutex.t;
  wrap : 'a -> 'b;
} -> 'b event

let wrap f (Evt r) = Evt {
  try_complete = r.try_complete;
  offer = r.offer;
  mutex = r.mutex;
  wrap = (fun x -> f (r.wrap x));
}

(* Per-case state after the offer phase. *)
type 'b offered = Offered : {
  slot : 'a option ref;
  wrap : 'a -> 'b;
} -> 'b offered

let select events =
  let events = Array.of_list events in
  let n = Array.length events in
  if n = 0 then invalid_arg "Select.select: empty case list";

  (* Deduplicate mutexes and sort by address for lock ordering. *)
  let mutexes =
    Array.to_list events
    |> List.map (fun (Evt { mutex; _ }) -> mutex)
    |> List.sort_uniq compare
  in
  let lock_all () = List.iter Mutex.lock mutexes in
  let unlock_all () = List.iter Mutex.unlock mutexes in

  (* Phase 1 — lock all sync objects *)
  lock_all ();

  (* Phase 2 — scan for an immediately ready case (under lock).
     Start from a random offset to avoid starvation (cf. Go's pollorder). *)
  let start = Random.int n in
  let rec scan count =
    if count >= n then None
    else
      let i = (start + count) mod n in
      let (Evt { try_complete; wrap; _ }) = events.(i) in
      match try_complete () with
      | Some v -> Some (fun () -> wrap v)
      | None -> scan (count + 1)
  in
  match scan 0 with
  | Some k ->
      unlock_all ();
      k ()
  | None ->
      (* Phase 3 — create one shared trigger, offer all cases (under lock) *)
      let trigger = Trigger.create () in
      let offered = Array.init n (fun i ->
        let (Evt { offer; wrap; _ }) = events.(i) in
        let slot = ref None in
        offer slot trigger;
        Offered { slot; wrap }
      ) in

      (* Phase 4 — unlock *)
      unlock_all ();

      (* Phase 5 — block until one counterpart signals the trigger *)
      Trigger.await trigger;

      (* Phase 6 — re-lock and find the winning case.
         The counterpart writes the slot under the same lock, so by the
         time we acquire it, the slot is guaranteed to be visible. *)
      lock_all ();
      let rec find_winner i =
        if i >= n then begin
          unlock_all ();
          failwith "Select: bug — no winner found"
        end else
          let (Offered { slot; wrap }) = offered.(i) in
          match !slot with
          | Some v ->
              unlock_all ();
              wrap v
          | None -> find_winner (i + 1)
      in
      find_winner 0
