open Effect
open Effect.Deep

type _ Effect.t += E : unit t
                 | F : unit t

(*
exception Unhandled: 'a t -> exn
(** Raised by [perform] when no handler is found for 
      the performed effect. *)

--> Exception: Stdlib.Effect.Unhandled(E)
*)
let f () =
  try perform E with
  | Unhandled E -> Printf.printf "Caught Unhandled E\n"

let g () =
  match f () with
  | x -> x
  | effect F, k ->
      continue k ()

let _ = g ()
