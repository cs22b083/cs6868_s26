open Golike_multicore_select

(* Select with one channel immediately ready *)
let () =
  Printf.printf "=== Select one channel ready ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 1 in
    let ch2 = Chan.make 1 in
    Chan.send ch1 42;
    let v = Select.select [
      Chan.recvEvt ch1;
      Chan.recvEvt ch2;
    ] in
    Printf.printf "  Got: %d\n" v;
    assert (v = 42)
  );
  Printf.printf "  PASSED\n"
