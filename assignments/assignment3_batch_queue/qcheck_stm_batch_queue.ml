(** QCheck-STM State Machine Test for Batch Bounded Blocking Queue

    This test verifies the batch queue's non-blocking operations against
    a sequential model using QCheck's State Machine Testing framework.

    == Your Task ==

    Complete the TODO sections below. The structure is provided, but you
    need to implement the key testing functions that define correctness.

    Study the examples from Lecture 3:
    - qcheck_stm_lockfree.ml

    == What is STM Testing? ==

    State Machine Testing compares your concurrent implementation against
    a simple sequential model:

    1. We define a model state (a list of ints representing queue contents)
    2. Each command (Try_enq/Try_deq/Size/Capacity) has:
       - next_state: how it should update the model
       - run: how to execute it on the real implementation
       - postcond: verify real result matches model prediction
    3. QCheck generates random command sequences and checks if real
       execution matches model
*)

open QCheck
open STM

module BQ = BatchQueue

let queue_capacity = 6

type cmd =
  | Try_enq of int array
  | Try_deq of int
  | Size
  | Capacity

let show_cmd = function
  | Try_enq items ->
    Printf.sprintf "Try_enq([|%s|])"
      (Array.to_list items |> List.map string_of_int |> String.concat "; ")
  | Try_deq n -> Printf.sprintf "Try_deq(%d)" n
  | Size -> "Size"
  | Capacity -> "Capacity"

let arb_cmd _state =
  let batch_gen = Gen.(array_size (int_range 1 3) (int_range 0 99)) in
  QCheck.make ~print:show_cmd
    (Gen.oneof [
       Gen.map (fun arr -> Try_enq arr) batch_gen;
       Gen.map (fun n -> Try_deq n) (Gen.int_range 1 3);
       Gen.return Size;
       Gen.return Capacity;
     ])

(* ============================================================================
   TODO: Implement next_state

   Update the model state according to the command.
   This defines the "correct" sequential behavior.

   Model state is a list of ints (queue contents, head at front).

   Hints:
   - For Try_enq(items): if items fit (length + batch <= capacity),
     append them to the queue. Otherwise, queue is unchanged.
   - For Try_deq(n): if enough items (length >= n), remove the first n.
     Otherwise, queue is unchanged.
   - For Size and Capacity: queries don't change state.
   ============================================================================ *)
let next_state cmd state =
  match cmd with 
  | Try_enq items ->
    let k = Array.length items in
    if List.length state + k <= queue_capacity then
      state @ Array.to_list items (* convert array to list and append *)
    else
      state
  | Try_deq n ->
    if List.length state >= n then
      let rec pop k xs =
        if k = 0 then xs
        else
          match xs with
          | [] -> [] (* not possible btw*)
          | _ :: tl -> pop (k - 1) tl
      in
      pop n state
    else
      state
  | Size -> state
  | Capacity -> state

let precond _cmd _state = true

let run cmd sut =
  match cmd with
  | Try_enq items ->
    Res (bool, BQ.try_enq sut items)
  | Try_deq n ->
    Res (option (array int), BQ.try_deq sut n)
  | Size ->
    Res (int, BQ.size sut)
  | Capacity ->
    Res (int, BQ.capacity sut)

(* ============================================================================
   TODO: Implement postcond

   Check if the real result matches what the model predicts.

   Hints:
   - For Try_enq(items): result is bool.
     Should be true if items fit (length + batch <= capacity), false otherwise.
   - For Try_deq(n): result is int array option.
     Should be Some(first n items) if enough in queue, None otherwise.
   - For Size: should equal List.length state.
   - For Capacity: should equal queue_capacity.

   Pattern matching on STM results — note the capitalized type constructors
   and the tuple wrapping (compare with lowercase types in [run]):

     | Size, Res ((Int, _), actual_size) ->
         actual_size = List.length state
     | ...
   ============================================================================ *)
let postcond cmd state result =
  let take (n : int) (xs : int list) : int list =
    let rec aux k acc ys =
      if k = 0 then List.rev acc
      else
        match ys with
        | [] -> List.rev acc
        | h :: tl -> aux (k - 1) (h :: acc) tl
    in
    aux n [] xs
  in
  match cmd, result with
  | Try_enq items, Res ((Bool, _), ok) ->
    let can_fit = List.length state + Array.length items <= queue_capacity in
    ok = can_fit (* just check if can be enqueued or not *)

  | Try_deq n, Res ((Option (Array Int), _), got) ->
  if List.length state >= n then
    match got with
    | Some arr -> Array.to_list arr = take n state (* check the returned array *)
    | None -> false
  else
    got = None

  | Size, Res ((Int, _), actual_size) ->
    actual_size = List.length state

  | Capacity, Res ((Int, _), actual_cap) ->
    actual_cap = queue_capacity

  | _ -> false


module Spec = struct
  type sut = int BQ.t
  type state = int list
  type nonrec cmd = cmd

  let arb_cmd = arb_cmd
  let init_state = []
  let next_state = next_state
  let precond = precond
  let run = run
  let init_sut () = BQ.create queue_capacity
  let cleanup _ = ()
  let postcond = postcond
  let show_cmd = show_cmd
end

module Seq = STM_sequential.Make(Spec)
module Dom = STM_domain.Make(Spec)

let run_sequential_test () =
  Printf.printf "Running sequential STM test...\n\n%!";
  let seq_test = Seq.agree_test ~count:1000 ~name:"BatchQueue sequential" in
  QCheck_base_runner.run_tests ~verbose:true [seq_test]

let run_concurrent_test () =
  Printf.printf "Running concurrent STM test...\n\n%!";
  let arb_cmds_par =
    Dom.arb_triple 15 10 Spec.arb_cmd Spec.arb_cmd Spec.arb_cmd
  in
  let conc_test =
    QCheck.Test.make ~retries:10 ~count:200 ~name:"BatchQueue concurrent" arb_cmds_par
    @@ fun triple ->
    Dom.agree_prop_par triple
  in
  QCheck_base_runner.run_tests ~verbose:true [conc_test]

let () =
  let test_name = if Array.length Sys.argv > 1 then Sys.argv.(1) else "sequential" in
  match test_name with
  | "sequential" | "seq" -> ignore (run_sequential_test ())
  | "concurrent" | "conc" -> ignore (run_concurrent_test ())
  | _ ->
    Printf.eprintf "Usage: %s [sequential|concurrent]\n" Sys.argv.(0);
    exit 1
