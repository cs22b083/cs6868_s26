open Golike_multicore_select

(* Buffer fiber — select between recv and send on different channels *)
let () =
  Printf.printf "=== Buffer fiber ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let in_ch = Chan.make 0 in
    let out_ch = Chan.make 0 in
    let total = Atomic.make 0 in
    (* Producer: send 1..5 *)
    Sched.fork (fun () ->
      for i = 1 to 5 do Chan.send in_ch i done
    );
    (* Consumer: receive 5 values *)
    Sched.fork (fun () ->
      for _ = 1 to 5 do
        let v = Chan.recv out_ch in
        ignore (Atomic.fetch_and_add total v : int)
      done
    );
    (* Buffer fiber: shuttle values from in_ch to out_ch via select *)
    let q = Queue.create () in
    let forwarded = Atomic.make 0 in
    while Atomic.get forwarded < 5 do
      if Queue.is_empty q then
        Queue.push (Chan.recv in_ch) q
      else
        Select.select [
          Chan.recvEvt in_ch |> Select.wrap (fun v -> Queue.push v q);
          Chan.sendEvt out_ch (Queue.peek q)
            |> Select.wrap (fun () -> ignore (Queue.pop q); ignore (Atomic.fetch_and_add forwarded 1 : int));
        ]
    done;
    while Atomic.get total < 15 do Sched.yield () done;
    Printf.printf "  Total: %d\n" (Atomic.get total);
    assert (Atomic.get total = 15)
  );
  Printf.printf "  PASSED\n"
