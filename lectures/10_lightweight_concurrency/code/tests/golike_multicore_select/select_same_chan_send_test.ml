open Golike_multicore_select

(* Same-channel send+recv — sender side wins *)
let () =
  Printf.printf "=== Same-channel send wins ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch = Chan.make 0 in
    (* Fork a receiver — it will match our send_evt offer *)
    Sched.fork (fun () ->
      let v = Chan.recv ch in
      Printf.printf "  Receiver got: %d\n" v
    );
    let v = Select.select [
      Chan.recv_evt ch |> Select.wrap (fun v -> `Recv v);
      Chan.send_evt ch 42 |> Select.wrap (fun () -> `Sent);
    ] in
    (match v with
     | `Recv v -> Printf.printf "  Received %d\n" v
     | `Sent  -> Printf.printf "  Sent 42\n")
  );
  Printf.printf "  PASSED\n"
