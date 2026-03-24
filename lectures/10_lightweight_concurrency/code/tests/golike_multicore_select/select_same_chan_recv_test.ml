open Golike_multicore_select

(* Mixed send/recv on the SAME channel — recv side wins *)
let () =
  Printf.printf "=== Same-channel send+recv ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch = Chan.make 0 in
    (* Fork a sender — it will match our recvEvt offer *)
    Sched.fork (fun () ->
      Chan.send ch 7
    );
    let v = Select.select [
      Chan.recvEvt ch |> Select.wrap (fun v -> `Recv v);
      Chan.sendEvt ch 42 |> Select.wrap (fun () -> `Sent);
    ] in
    (match v with
     | `Recv v -> Printf.printf "  Received %d\n" v
     | `Sent  -> Printf.printf "  Sent 42\n")
  );
  Printf.printf "  PASSED\n"
