open Golike_multicore_select

(* IVar read_evt in select *)
let () =
  Printf.printf "=== IVar read_evt ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let iv = Ivar.create () in
    let ch = Chan.make 0 in
    Sched.fork (fun () ->
      Ivar.fill iv 42
    );
    let v = Select.select [
      Chan.recv_evt ch |> Select.wrap (fun v -> `Ch v);
      Ivar.read_evt iv |> Select.wrap (fun v -> `Iv v);
    ] in
    (match v with
     | `Ch v -> Printf.printf "  ch: %d\n" v
     | `Iv v -> Printf.printf "  ivar: %d\n" v)
  );
  Printf.printf "  PASSED\n"
