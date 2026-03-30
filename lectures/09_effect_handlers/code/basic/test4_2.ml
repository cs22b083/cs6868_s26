open Effect
open Effect.Deep

type _ Effect.t += E : string t
                 | F : string t

let comp n e =
  Printf.printf "%d " n;
  print_string (perform e);
  Printf.printf "%d " (n+3)

(* Extends test4.ml with two effects and two comp calls.
   Output: 0 1 2 3 4 5 6 7 8 9

   Execution trace:
   - comp 0 E prints 0, then perform E suspends.
     The continuation k captures everything remaining in the try block:
     "print result of E; print 3; comp 4 F".
   - E handler prints 1, then continue k "2 " resumes:
       - comp 0 E prints 2, then 3.
       - comp 4 F prints 4, then perform F suspends.
         k' captures "print result of F; print 7".
       - F handler prints 5, then continue k' "6 " resumes:
           - comp 4 F prints 6, then 7.
           - continue k' returns.
       - F handler prints 8.
       - continue k returns (the entire try body is now done).
   - E handler prints 9.

   Why 8 before 9: continue k doesn't return until everything inside k
   finishes — including comp 4 F and the F handler. So 8 (F handler's
   post-continue) prints while still inside E handler's continue k.
   Only when continue k finally returns does 9 print. *)
let main () =
  try
    comp 0 E; comp 4 F
  with
  | effect E, k ->
    print_string "1 ";
    continue k "2 ";
    print_string "9 "
  | effect F, k ->
    print_string "5 ";
    continue k "6 ";
    print_string "8 "

let () = main ()
