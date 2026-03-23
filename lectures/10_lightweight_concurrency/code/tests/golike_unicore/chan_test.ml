open Golike_unicore

(* Test 1: Unbuffered channel — ping pong *)
let () =
  Printf.printf "=== Ping Pong (unbuffered) ===\n";
  Sched.run (fun () ->
    let ch = Chan.make 0 in
    Sched.fork (fun () ->
      Chan.send ch "ping";
      let reply = Chan.recv ch in
      Printf.printf "  Fiber 1 got: %s\n" reply
    );
    let msg = Chan.recv ch in
    Printf.printf "  Main got: %s\n" msg;
    Chan.send ch "pong"
  )
(* Output:
  === Ping Pong (unbuffered) ===
    Main got: ping
    Fiber 1 got: pong
*)

(* Test 2: Buffered channel — producer/consumer *)
let () =
  Printf.printf "\n=== Producer/Consumer (buffered, cap=3) ===\n";
  Sched.run (fun () ->
    let ch = Chan.make 3 in
    Sched.fork (fun () ->
      for i = 1 to 5 do
        Printf.printf "  Sending %d\n" i;
        Chan.send ch i
      done
    );
    for _ = 1 to 5 do
      let v = Chan.recv ch in
      Printf.printf "  Received %d\n" v
    done
  )
(* Output:
  === Producer/Consumer (buffered, cap=3) ===
    Sending 1
    Sending 2
    Sending 3
    Sending 4
    Received 1
    Received 2
    Received 3
    Received 4
    Sending 5
    Received 5
*)


