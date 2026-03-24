(** Fibonacci generator using select + IVar cancellation (unicore).

    Port of the classic Go select-based fibonacci example:
    the generator sends fibonacci numbers on a channel until
    the consumer signals cancellation. *)

open Golike_unicore_select

exception Cancelled

let or_cancel cancel evt = Select.select [
  evt;
  Ivar.readEvt cancel |> Select.wrap (fun () -> raise Cancelled);
]

let () =
  Printf.printf "=== Fibonacci (select + IVar cancel) ===\n";
  let expected = [| 0; 1; 1; 2; 3; 5; 8; 13; 21; 34 |] in
  let n_fibs = 10 in
  let result = Array.make n_fibs 0 in
  Sched.run (fun () ->
    let cancel = Ivar.create () in
    let c = Chan.make 0 in

    let fibonacci out_ch =
      try
        let rec loop x y =
          or_cancel cancel (Chan.sendEvt out_ch x);
          loop y (x + y)
        in
        loop 0 1
      with Cancelled -> ()
    in

    Sched.fork (fun () -> fibonacci c);
    for i = 0 to n_fibs - 1 do
      let v = Chan.recv c in
      result.(i) <- v;
      Printf.printf "  %d\n" v
    done;
    Ivar.fill cancel ()
  );
  assert (result = expected);
  Printf.printf "  PASSED\n"

(* Expected output:
   === Fibonacci (select + IVar cancel) ===
     0
     1
     1
     2
     3
     5
     8
     13
     21
     34
     PASSED
*)
