[@@@alert "-do_not_spawn_domains"]

(* The fix at the top level: use Portable.Atomic instead of stdlib's
   Atomic. Portable.Atomic.t mode-crosses BOTH contention AND
   portability — it's always portable regardless of where it's
   defined or what it stores. *)

open Portable

let count = Atomic.make 0

let gensym prefix =
  let n = Atomic.fetch_and_add count 1 in
  prefix ^ "_" ^ string_of_int n

let _ = Domain.Safe.spawn (fun () -> gensym "x")

(* Compiles. Compare with gensym_atomic.ml: same shape, but stdlib's
   Atomic.t mode-crosses only contention, not portability — and a
   top-level let-binding capturing it is therefore nonportable.

   Portable.Atomic gives you both. This still isn't capsules (Part 5),
   but it's the right answer when you really do want a top-level
   shared atomic counter that any portable closure can use. *)
