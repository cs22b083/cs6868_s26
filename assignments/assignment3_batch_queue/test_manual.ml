(**
 Manual concurrent tests for Batch Bounded Blocking Queue *)

let printf = Printf.printf

let assert_array_eq a b msg =
  if a <> b then begin
    printf "FAIL: %s\n  expected: [|%s|]\n  got:      [|%s|]\n" msg
      (Array.to_list a |> List.map string_of_int |> String.concat "; ")
      (Array.to_list b |> List.map string_of_int |> String.concat "; ");
    exit 1
  end

(* Helper functions *)
(* Assert the condition *)
let assert_true cond msg =
  if not cond then begin
    printf "FAIL: %s\n" msg;
    exit 1
  end
(* Check for Invalid_argument *)
let expect_invalid f msg =
  try
    let _ = f () in
    printf "FAIL: %s (expected Invalid_argument)\n" msg;
    exit 1
  with
  | Invalid_argument _ -> ()

(** Test create, enq, deq, size, capacity in a single thread. *)
let test_sequential_basic () =
  let q = BatchQueue.create 5 in
  assert_true (BatchQueue.capacity q = 5) "capacity should be 5";
  assert_true (BatchQueue.size q = 0) "initial size should be 0";
  BatchQueue.enq q [|1; 2; 3|];
  assert_true (BatchQueue.size q = 3) "size after enq should be 3";
  assert_array_eq [|1; 2|] (BatchQueue.deq q 2) "deq(2) should return first two";
  assert_true (BatchQueue.size q = 1) "size after deq should be 1";
  assert_array_eq [|3|] (BatchQueue.deq q 1) "deq(1) should return remaining";
  assert_true (BatchQueue.size q = 0) "final size should be 0" 

(** Test that invalid arguments raise [Invalid_argument]. *)
let test_error_handling () =
  expect_invalid (fun () -> BatchQueue.create 0) "create 0";
  expect_invalid (fun () -> BatchQueue.create (-1)) "create -1";

  let q = BatchQueue.create 4 in
  expect_invalid (fun () -> BatchQueue.enq q [||]) "enq empty";
  expect_invalid (fun () -> BatchQueue.enq q [|1;2;3;4;5|]) "enq > capacity";
  expect_invalid (fun () -> ignore (BatchQueue.try_enq q [||])) "try_enq empty";
  expect_invalid (fun () -> ignore (BatchQueue.try_enq q [|1;2;3;4;5|])) "try_enq > capacity";

  expect_invalid (fun () -> ignore (BatchQueue.deq q 0)) "deq 0";
  expect_invalid (fun () -> ignore (BatchQueue.deq q 5)) "deq > capacity";
  expect_invalid (fun () -> ignore (BatchQueue.try_deq q 0)) "try_deq 0";
  expect_invalid (fun () -> ignore (BatchQueue.try_deq q 5)) "try_deq > capacity"


(** Test that deq blocks until items arrive (and/or enq blocks until space frees). *)
let test_blocking_enq_deq () =
  (* Blocked Deque *)
  let q = BatchQueue.create 2 in

  let deq_done = Atomic.make false in
  let deq_res = Atomic.make [||] in
  let d_deq =
    Domain.spawn (fun () ->
        let r = BatchQueue.deq q 1 in
        Atomic.set deq_res r;
        Atomic.set deq_done true)
  in
  assert_true (not (Atomic.get deq_done)) "deq should block on empty queue";
  BatchQueue.enq q [|42|];
  Domain.join d_deq;
  assert_array_eq [|42|] (Atomic.get deq_res) "blocked deq should receive enqueued item";

  (* Blocked enqueue *)
  BatchQueue.enq q [|1; 2|];
  let enq_done = Atomic.make false in
  let d_enq =
    Domain.spawn (fun () ->
        BatchQueue.enq q [|3|];
        Atomic.set enq_done true)
  in
  assert_true (not (Atomic.get enq_done)) "enq should block on full queue";
  ignore (BatchQueue.deq q 1);
  Domain.join d_enq;
  assert_true (Atomic.get enq_done) "blocked enq should complete after space frees";
  assert_array_eq [|2; 3|] (BatchQueue.deq q 2) "queue content after unblock"

(** Test that a single producer/consumer pair sees items in FIFO order. *)
let test_fifo_single_producer_consumer () =
  let q = BatchQueue.create 32 in
  let n = 200 in
  let consumed = Array.make n (-1) in

  let prod =
    Domain.spawn (fun () ->
        for i = 1 to n do
          BatchQueue.enq q [|i|]
        done)
  in
  let cons =
    Domain.spawn (fun () ->
        for i = 0 to n - 1 do
          let x = BatchQueue.deq q 1 in
          consumed.(i) <- x.(0)
        done)
  in

  Domain.join prod;
  Domain.join cons;

  for i = 0 to n - 1 do
    assert_true (consumed.(i) = i + 1) "producer/consumer FIFO order violated"
  done

(** Test dequeuer head-of-line blocking: deq(5) arrives before deq(2);
    even when 6 items are enqueued, deq(5) must be served first. *)
let test_dequeuer_head_of_line_blocking () =
  let q = BatchQueue.create 8 in

  let a_done = Atomic.make false in
  let b_done = Atomic.make false in
  let a_res = Atomic.make [||] in
  let b_res = Atomic.make [||] in

  let da =
    Domain.spawn (fun () ->
        Atomic.set a_res (BatchQueue.deq q 5);
        Atomic.set a_done true)
  in
  let db =
    Domain.spawn (fun () ->
        Atomic.set b_res (BatchQueue.deq q 2);
        Atomic.set b_done true)
  in

  BatchQueue.enq q [|1;2;3;4;5;6|];
  Domain.join da;
   (* I know that the deq(5) will complete. So joining the thread early so that it 
   assertion after deq thread is notified *)
  assert_true (Atomic.get a_done) "deq(5) should complete first";
  assert_true (not (Atomic.get b_done)) "deq(2) must wait behind head waiter";

  BatchQueue.enq q [|7|];
  (* Domain.join da; *)
  Domain.join db;

  assert_array_eq [|1;2;3;4;5|] (Atomic.get a_res) "deq(5) result";
  assert_array_eq [|6;7|] (Atomic.get b_res) "deq(2) result after head waiter"


(** Test enqueuer head-of-line blocking: enq(3) arrives before enq(1);
    freeing 1 slot must NOT let enq(1) jump ahead. *)
let test_enqueuer_head_of_line_blocking () =
  let q = BatchQueue.create 8 in
  BatchQueue.enq q [|1;2;3;4;5;6;7;8|];

  let a_done = Atomic.make false in
  let b_done = Atomic.make false in
 (* 3elements enqueue*)
  let da =
    Domain.spawn (fun () ->
        BatchQueue.enq q [|101;102;103|];
        Atomic.set a_done true)
  in
  (* 1 elements enqueue *)
  let db =
    Domain.spawn (fun () ->
        BatchQueue.enq q [|201|];
        Atomic.set b_done true)
    in

  ignore (BatchQueue.deq q 1);
  assert_true (not (Atomic.get a_done)) "enq(3) still needs more space";
  assert_true (not (Atomic.get b_done)) "enq(1) must not jump ahead";

  ignore (BatchQueue.deq q 2);
  (* Waiting for notification and enqueue complete *)
  Domain.join da;
  assert_true (Atomic.get a_done) "head enq(3) should proceed when 3 slots free";
  assert_true (not (Atomic.get b_done)) "enq(1) should still wait if no slot remains";
    (* dequeue to finish the enqueuer's task *)
  ignore (BatchQueue.deq q 1);
  Domain.join db;
 (* ONCE check the final array *)
  let rest = BatchQueue.deq q 8 in
  assert_array_eq [|5;6;7;8;101;102;103;201|] rest "enq FIFO head-of-line order"


(** Test that no items are lost or duplicated under concurrent access. *)
let test_no_lost_items () =
  let q = BatchQueue.create 64 in
  let producers = 4 in
  let consumers = 4 in
  let per_producer = 250 in
  let total = producers * per_producer in

  let out = Array.make total (-1) in
  let expected_out = Array.make total(-1) in
  let idx = Atomic.make 0 in
 (* for each producer insert 1-250, 1000001-1000250, ...... *)
  let prod_domains =
    Array.init producers (fun p ->
        Domain.spawn (fun () ->
            for i = 1 to per_producer do
              let id = (p * 1_000_000) + i in
              BatchQueue.enq q [|id|]
            done))
  in

  let cons_domains =
    Array.init consumers (fun _ ->
        Domain.spawn (fun () ->
            for _ = 1 to (total / consumers) do
              let v = (BatchQueue.deq q 1).(0) in
              let pos = Atomic.fetch_and_add idx 1 in
              out.(pos) <- v
            done))
  in

  Array.iter Domain.join prod_domains;
  Array.iter Domain.join cons_domains; (* Waiting till both prod and consumer succeed. *)

  assert_true (Atomic.get idx = total) "consumed count mismatch check"; (* Check if no lost *)
  
  let counts = Hashtbl.create total in
  Array.iter (fun v ->
      assert_true (v <> -1) "uninitialized consumed slot";
      let c = match Hashtbl.find_opt counts v with Some x -> x | None -> 0 in
      Hashtbl.replace counts v (c + 1)
    ) out;

  for p = 0 to producers - 1 do
    for i = 1 to per_producer do
      let id = (p * 1_000_000) + i in
      expected_out.(p * per_producer + i - 1) <- id
    done
  done;
  (* sort the out array *)
  Array.sort compare out;
  (* Array.sort compare expected_out; *)
  assert_true (expected_out = out) "Check No missing and duplicates"

(** Test that a batch enqueue is not interleaved with another batch. *)
let test_batch_atomicity () =
  let q = BatchQueue.create 6 in
  let d1 = Domain.spawn (fun () -> BatchQueue.enq q [|1;1;1|]) in
  let d2 = Domain.spawn (fun () -> BatchQueue.enq q [|2;2;2|]) in
  Domain.join d1;
  Domain.join d2;

  let out = BatchQueue.deq q 6 in
  let a = [|1;1;1;2;2;2|] in
  let b = [|2;2;2;1;1;1|] in
  (* Either d1 --> d2 or d2 --> d1 *)
  assert_true (out = a || out = b) "batch enqueue interleaving detected"

(** Stress test: multiple producers and consumers with many operatons. *)
let test_stress () =
  let q = BatchQueue.create 96 in
  let producers = 4 in
  let consumers = 4 in
  let batches_per_producer = 200 in
  let batch_size = 3 in
  let total = producers * batches_per_producer * batch_size in
 (* each producer enqueues "batches" and each batch has 3 elements *)
  let out = Array.make total (-1) in
  let expected_out =  Array.make total (-1) in 
  let idx = Atomic.make 0 in
  let idx2 = ref 0 in 

  (* Each batch enqueues unique element *)
  let prod_domains =
    Array.init producers (fun p ->
        Domain.spawn (fun () ->
            for b = 1 to batches_per_producer do
              let base = (p * 1_000_000) + (b * 10) in
              BatchQueue.enq q [|base; base + 1; base + 2|]
            done))
  in

  let cons_domains =
    Array.init consumers (fun _ ->
        Domain.spawn (fun () ->
            for _ = 1 to (total / producers / batch_size) do
              let arr = BatchQueue.deq q batch_size in
              for i = 0 to batch_size - 1 do
                let pos = Atomic.fetch_and_add idx 1 in
                out.(pos) <- arr.(i)
              done
            done))
  in

  Array.iter Domain.join prod_domains;
  Array.iter Domain.join cons_domains;

  assert_true (Atomic.get idx = total) "stress test : consumed count mismatch";

  for p = 0 to producers - 1 do
    for b = 1 to batches_per_producer do
      let base = (p * 1_000_000) + (b * 10) in
      expected_out.(!idx2) <- base;
      expected_out.(!idx2 + 1) <- base + 1;
      expected_out.(!idx2 + 2) <- base + 2;
      idx2 := !idx2 + 3
    done
  done;

  Array.sort compare out;
  (* Array.sort compare expected_out; *)
  assert_true (expected_out = out) "Check No missing and duplicates"

let () =
  test_sequential_basic ();
  test_error_handling ();
  test_blocking_enq_deq ();
  test_fifo_single_producer_consumer ();
  test_dequeuer_head_of_line_blocking ();
  test_enqueuer_head_of_line_blocking ();
  test_no_lost_items ();
  test_batch_atomicity ();
  test_stress ();
  printf "\nAll manual tests passed!\n"