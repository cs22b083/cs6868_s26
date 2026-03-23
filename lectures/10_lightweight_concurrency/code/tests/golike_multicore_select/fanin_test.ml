open Golike_multicore_select

(* Fan-in with select — known to be flaky under multicore scheduling.
   Two senders on rendezvous channels, one receiver using select.
   Under contention, a select may consume a value from one channel while
   both senders race, leading to a lost wakeup / double-consume. *)
let () =
  Printf.printf "=== Select fan-in ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 0 in
    let ch2 = Chan.make 0 in
    let total = Atomic.make 0 in
    Sched.fork (fun () ->
      for i = 1 to 3 do
        Chan.send ch1 (i * 10)
      done
    );
    Sched.fork (fun () ->
      for i = 1 to 3 do
        Chan.send ch2 (i * 100)
      done
    );
    for _ = 1 to 6 do
      let v = Select.select [
        Chan.recvEvt ch1;
        Chan.recvEvt ch2;
      ] in
      ignore (Atomic.fetch_and_add total v : int)
    done;
    Printf.printf "  Total: %d\n" (Atomic.get total);
    assert (Atomic.get total = 10 + 20 + 30 + 100 + 200 + 300)
  );
  Printf.printf "  PASSED\n"
