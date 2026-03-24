open Golike_multicore_select

(* Select blocks until one case becomes ready *)
let () =
  Printf.printf "=== Select blocks until ready ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 0 in
    let ch2 = Chan.make 0 in
    Sched.fork (fun () ->
      Chan.send ch2 99
    );
    let v = Select.select [
      Chan.recvEvt ch1 |> Select.wrap (fun v -> `Ch1 v);
      Chan.recvEvt ch2 |> Select.wrap (fun v -> `Ch2 v);
    ] in
    (match v with
     | `Ch1 v -> Printf.printf "  ch1: %d\n" v
     | `Ch2 v -> Printf.printf "  ch2: %d\n" v)
  );
  Printf.printf "  PASSED\n"
