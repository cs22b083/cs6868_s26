open Golike_multicore_select

(* Select where second case is ready *)
let () =
  Printf.printf "=== Select second case ready ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 1 in
    let ch2 = Chan.make 1 in
    Chan.send ch2 77;
    let v = Select.select [
      Chan.recvEvt ch1;
      Chan.recvEvt ch2;
    ] in
    Printf.printf "  Got: %d\n" v;
    assert (v = 77)
  );
  Printf.printf "  PASSED\n"
