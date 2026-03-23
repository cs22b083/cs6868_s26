open Golike_multicore

(* Test 1: Unbuffered channel — ping pong *)
let () =
  Printf.printf "=== Test 1: Ping Pong (unbuffered) ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch = Chan.make 0 in
    Sched.fork (fun () ->
      Chan.send ch "ping";
      let reply = Chan.recv ch in
      Printf.printf "  Fiber 1 got: %s\n" reply
    );
    let msg = Chan.recv ch in
    Printf.printf "  Main got: %s\n" msg;
    Chan.send ch "pong"
  );
  Printf.printf "  PASSED\n"

(* Test 2: Buffered channel — producer/consumer *)
let () =
  Printf.printf "\n=== Test 2: Producer/Consumer (buffered, cap=3) ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch = Chan.make 3 in
    let sum = Atomic.make 0 in
    Sched.fork (fun () ->
      for i = 1 to 10 do
        Chan.send ch i
      done
    );
    for _ = 1 to 10 do
      let v = Chan.recv ch in
      ignore (Atomic.fetch_and_add sum v : int)
    done;
    assert (Atomic.get sum = 55)
  );
  Printf.printf "  PASSED\n"

(* Test 3: Multiple producers, multiple consumers *)
let () =
  Printf.printf "\n=== Test 3: Multi-producer, multi-consumer ===\n";
  Sched.run ~num_domains:4 (fun () ->
    let ch = Chan.make 5 in
    let total = Atomic.make 0 in
    let n_producers = 4 in
    let items_per_producer = 100 in
    (* Each producer sends items_per_producer values of 1 *)
    for _ = 1 to n_producers do
      Sched.fork (fun () ->
        for _ = 1 to items_per_producer do
          Chan.send ch 1
        done
      )
    done;
    (* Single consumer collects all *)
    for _ = 1 to n_producers * items_per_producer do
      let v = Chan.recv ch in
      ignore (Atomic.fetch_and_add total v : int)
    done;
    assert (Atomic.get total = n_producers * items_per_producer)
  );
  Printf.printf "  PASSED\n"


