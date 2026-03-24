open Golike_unicore_select

(* Test 1: select with one channel immediately ready *)
let () =
  Printf.printf "=== Select: one channel ready ===\n";
  Sched.run (fun () ->
    let ch1 = Chan.make 1 in
    let ch2 = Chan.make 1 in
    Chan.send ch1 42;
    let v = Select.select [
      Chan.recvEvt ch1;
      Chan.recvEvt ch2;
    ] in
    Printf.printf "  Got: %d\n" v
  )

(* Test 2: select blocks until one case becomes ready *)
let () =
  Printf.printf "\n=== Select: blocks until ready ===\n";
  Sched.run (fun () ->
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
  )

(* Test 3: select with send cases *)
let () =
  Printf.printf "\n=== Select: send cases ===\n";
  Sched.run (fun () ->
    let ch1 = Chan.make 0 in
    let ch2 = Chan.make 0 in
    Sched.fork (fun () ->
      let v = Chan.recv ch2 in
      Printf.printf "  Receiver got from ch2: %d\n" v
    );
    Select.select [
      Chan.sendEvt ch1 1 |> Select.wrap (fun () -> Printf.printf "  Sent 1 on ch1\n");
      Chan.sendEvt ch2 2 |> Select.wrap (fun () -> Printf.printf "  Sent 2 on ch2\n");
    ]
  )

(* Test 4: fan-in with select *)
let () =
  Printf.printf "\n=== Select: fan-in ===\n";
  Sched.run (fun () ->
    let ch1 = Chan.make 0 in
    let ch2 = Chan.make 0 in
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
      Printf.printf "  Got: %d\n" v
    done
  )

(* Test 5: mixed send and recv in one select *)
let () =
  Printf.printf "\n=== Select: mixed send/recv ===\n";
  Sched.run (fun () ->
    let in_ch = Chan.make 0 in
    let out_ch = Chan.make 0 in
    Sched.fork (fun () ->
      Chan.send in_ch 7
    );
    Sched.fork (fun () ->
      let v = Chan.recv out_ch in
      Printf.printf "  out_ch receiver got: %d\n" v
    );
    Select.select [
      Chan.recvEvt in_ch |> Select.wrap (fun v -> Printf.printf "  Received %d from in_ch\n" v);
      Chan.sendEvt out_ch 42 |> Select.wrap (fun () -> Printf.printf "  Sent 42 on out_ch\n");
    ]
  )

(* Test 6: select where second case is ready (first is not) *)
let () =
  Printf.printf "\n=== Select: second case ready ===\n";
  Sched.run (fun () ->
    let ch1 = Chan.make 1 in
    let ch2 = Chan.make 1 in
    Chan.send ch2 77;
    let v = Select.select [
      Chan.recvEvt ch1 |> Select.wrap (fun v -> `Ch1 v);
      Chan.recvEvt ch2 |> Select.wrap (fun v -> `Ch2 v);
    ] in
    (match v with
     | `Ch1 v -> Printf.printf "  ch1: %d\n" v
     | `Ch2 v -> Printf.printf "  ch2: %d\n" v)
  )

(* Test 7: multiple selects in sequence *)
let () =
  Printf.printf "\n=== Select: multiple rounds ===\n";
  Sched.run (fun () ->
    let ch = Chan.make 0 in
    Sched.fork (fun () ->
      for i = 1 to 3 do
        Chan.send ch i
      done
    );
    for _ = 1 to 3 do
      let v = Select.select [
        Chan.recvEvt ch;
      ] in
      Printf.printf "  Got: %d\n" v
    done
  )

(* Test 8: IVar readEvt in select *)
let () =
  Printf.printf "\n=== Select: IVar readEvt ===\n";
  Sched.run (fun () ->
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
  )

(* Test 9: IVar already filled — select returns immediately *)
let () =
  Printf.printf "\n=== Select: IVar already filled ===\n";
  Sched.run (fun () ->
    let iv = Ivar.create () in
    Ivar.fill iv 99;
    let v = Select.select [
      Ivar.readEvt iv;
    ] in
    Printf.printf "  Got: %d\n" v
  )

(* Test 10: mixed send/recv on the SAME channel *)
let () =
  Printf.printf "\n=== Select: same-channel send+recv ===\n";
  Sched.run (fun () ->
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
  )

(* Test 11: same-channel send+recv, sender side wins *)
let () =
  Printf.printf "\n=== Select: same-channel send wins ===\n";
  Sched.run (fun () ->
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
  )

(* Test 12: buffer fiber — select between recv and send on different channels *)
let () =
  Printf.printf "\n=== Select: buffer fiber ===\n";
  Sched.run (fun () ->
    let in_ch = Chan.make 0 in
    let out_ch = Chan.make 0 in
    let total = ref 0 in
    (* Producer: send 1..5 *)
    Sched.fork (fun () ->
      for i = 1 to 5 do Chan.send in_ch i done
    );
    (* Consumer: receive 5 values *)
    Sched.fork (fun () ->
      for _ = 1 to 5 do
        let v = Chan.recv out_ch in
        total := !total + v
      done
    );
    (* Buffer fiber: shuttle values from in_ch to out_ch via select *)
    let q = Queue.create () in
    let forwarded = ref 0 in
    while !forwarded < 5 do
      if Queue.is_empty q then begin
        Queue.push (Chan.recv in_ch) q
      end else begin
        Select.select [
          Chan.recvEvt in_ch |> Select.wrap (fun v -> Queue.push v q);
          Chan.sendEvt out_ch (Queue.peek q)
            |> Select.wrap (fun () -> ignore (Queue.pop q); incr forwarded);
        ]
      end
    done;
    (* Let the consumer process the last forwarded value *)
    while !total < 15 do Sched.yield () done;
    Printf.printf "  Total: %d\n" !total;
    assert (!total = 15)
  )
