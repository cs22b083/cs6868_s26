open Golike_multicore_select

(* Select with send cases *)
let () =
  Printf.printf "=== Select send cases ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 0 in
    let ch2 = Chan.make 0 in
    let received = Atomic.make 0 in
    Sched.fork (fun () ->
      let v = Chan.recv ch2 in
      Atomic.set received v
    );
    Select.select [
      Chan.send_evt ch1 1;
      Chan.send_evt ch2 2;
    ];
    while Atomic.get received = 0 do Sched.yield () done;
    Printf.printf "  Receiver got: %d\n" (Atomic.get received)
  );
  Printf.printf "  PASSED\n"
