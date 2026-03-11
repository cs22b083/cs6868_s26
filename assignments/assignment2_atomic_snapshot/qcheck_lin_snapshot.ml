(** QCheck-Lin Linearizability Test for Atomic Snapshot

    This test verifies that the atomic snapshot implementation is linearizable
    under concurrent access.

    == Your Task ==

    Implement the QCheck-Lin specification for the atomic snapshot.
    Follow the examples from Lecture 3:
    - qcheck_lin_bounded.ml
    - qcheck_lin_lockfree.ml

    You need to:
    1. Define the Lin API specification module (SnapshotSig)
    2. Specify init() and cleanup() functions
    3. Define the api list using Lin's DSL (val_ combinator)
    4. Generate and run the linearizability test

    == Lin DSL Type Descriptors ==

    The Snapshot.scan function returns 'int array'. Use:
      returning (array int)

    The others are standard and follow the API from the lectures.

    == Expected Result ==

    This test should PASS. The double-collect algorithm ensures linearizability:
    every scan returns a consistent snapshot that corresponds to some actual
    state that existed during the scan operation.
*)

module SnapshotSig = struct
  type t = int Snapshot.t

  let n = 4
  let init () = Snapshot.create n 0
  let cleanup _ = ()

  open Lin

  let int_small = nat_small
  (*
     Bound the generated index at call-site to avoid exceptions. *)
  let update_bounded snapshot idx value =
    Snapshot.update snapshot (idx mod n) value

  let api =
    [ val_ "update" update_bounded (t @-> int_small @-> int_small @-> returning unit);
      val_ "scan" Snapshot.scan (t @-> returning (array int)); ]
end

module Snapshot_domain = Lin_domain.Make(SnapshotSig)

let () =
  QCheck_base_runner.run_tests_main [
    Snapshot_domain.lin_test ~count:1000 ~name:"Atomic Snapshot (double-collect)";
  ]
