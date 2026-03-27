open Golike_multicore_select

(* Multiple selects in sequence *)
let () =
  Printf.printf "=== Select multiple rounds ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch = Chan.make 0 in
    Sched.fork (fun () ->
      for i = 1 to 5 do
        Chan.send ch i
      done
    );
    let total = ref 0 in
    for _ = 1 to 5 do
      let v = Select.select [
        Chan.recv_evt ch;
      ] in
      total := !total + v
    done;
    Printf.printf "  Total: %d\n" !total;
    assert (!total = 15)
  );
  Printf.printf "  PASSED\n"
