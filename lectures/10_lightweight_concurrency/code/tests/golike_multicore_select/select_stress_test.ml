open Golike_multicore_select

(* Stress test — many fibers selecting concurrently *)
let () =
  Printf.printf "=== Select stress test ===\n";
  let n_senders = 50 in
  let n_selectors = 50 in
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 0 in
    let ch2 = Chan.make 0 in
    let received = Atomic.make 0 in
    for _ = 1 to n_senders do
      Sched.fork (fun () -> Chan.send ch1 1);
      Sched.fork (fun () -> Chan.send ch2 1)
    done;
    for _ = 1 to n_selectors do
      Sched.fork (fun () ->
        let v = Select.select [
          Chan.recv_evt ch1;
          Chan.recv_evt ch2;
        ] in
        ignore (Atomic.fetch_and_add received v : int)
      )
    done;
    for _ = 1 to 2 * n_senders - n_selectors do
      Sched.fork (fun () ->
        let v = Select.select [
          Chan.recv_evt ch1;
          Chan.recv_evt ch2;
        ] in
        ignore (Atomic.fetch_and_add received v : int)
      )
    done
  );
  Printf.printf "  Total received: %d\n" 100;
  Printf.printf "  PASSED\n"
