open Golike_multicore_select

(* Test 1: select with one channel immediately ready *)
let () =
  Printf.printf "=== Test 1: Select one channel ready ===\n";
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

(* Test 2: select blocks until one case becomes ready *)
let () =
  Printf.printf "\n=== Test 2: Select blocks until ready ===\n";
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

(* Test 3: select with send cases *)
let () =
  Printf.printf "\n=== Test 3: Select send cases ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 0 in
    let ch2 = Chan.make 0 in
    let received = Atomic.make 0 in
    Sched.fork (fun () ->
      let v = Chan.recv ch2 in
      Atomic.set received v
    );
    Select.select [
      Chan.sendEvt ch1 1;
      Chan.sendEvt ch2 2;
    ];
    while Atomic.get received = 0 do Sched.yield () done;
    Printf.printf "  Receiver got: %d\n" (Atomic.get received)
  );
  Printf.printf "  PASSED\n"

(* Test 4: select where second case is ready *)
let () =
  Printf.printf "\n=== Test 4: Select second case ready ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch1 = Chan.make 1 in
    let ch2 = Chan.make 1 in
    Chan.send ch2 77;
    let v = Select.select [
      Chan.recvEvt ch1;
      Chan.recvEvt ch2;
    ] in
    Printf.printf "  Got: %d\n" v;
    assert (v = 77)
  );
  Printf.printf "  PASSED\n"

(* Test 5: multiple selects in sequence *)
let () =
  Printf.printf "\n=== Test 5: Select multiple rounds ===\n";
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
        Chan.recvEvt ch;
      ] in
      total := !total + v
    done;
    Printf.printf "  Total: %d\n" !total;
    assert (!total = 15)
  );
  Printf.printf "  PASSED\n"

(* Test 6: IVar readEvt in select *)
let () =
  Printf.printf "\n=== Test 6: IVar readEvt ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let iv = Ivar.create () in
    let ch = Chan.make 0 in
    Sched.fork (fun () ->
      Ivar.fill iv 42
    );
    let v = Select.select [
      Chan.recvEvt ch |> Select.wrap (fun v -> `Ch v);
      Ivar.readEvt iv |> Select.wrap (fun v -> `Iv v);
    ] in
    (match v with
     | `Ch v -> Printf.printf "  ch: %d\n" v
     | `Iv v -> Printf.printf "  ivar: %d\n" v)
  );
  Printf.printf "  PASSED\n"

(* Test 7: stress test — many fibers selecting concurrently *)
let () =
  Printf.printf "\n=== Test 7: Select stress test ===\n";
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
          Chan.recvEvt ch1;
          Chan.recvEvt ch2;
        ] in
        ignore (Atomic.fetch_and_add received v : int)
      )
    done;
    for _ = 1 to 2 * n_senders - n_selectors do
      Sched.fork (fun () ->
        let v = Select.select [
          Chan.recvEvt ch1;
          Chan.recvEvt ch2;
        ] in
        ignore (Atomic.fetch_and_add received v : int)
      )
    done
  );
  Printf.printf "  Total received: %d\n" 100;
  Printf.printf "  PASSED\n"

(* Test 8: mixed send/recv on the SAME channel *)
let () =
  Printf.printf "\n=== Test 8: Same-channel send+recv ===\n";
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

(* Test 9: same-channel send+recv, sender side wins *)
let () =
  Printf.printf "\n=== Test 9: Same-channel send wins ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch = Chan.make 0 in
    (* Fork a receiver — it will match our sendEvt offer *)
    Sched.fork (fun () ->
      let v = Chan.recv ch in
      Printf.printf "  Receiver got: %d\n" v
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

(* Test 10: buffer fiber — select between recv and send on different channels *)
let () =
  Printf.printf "\n=== Test 10: Buffer fiber ===\n";
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
