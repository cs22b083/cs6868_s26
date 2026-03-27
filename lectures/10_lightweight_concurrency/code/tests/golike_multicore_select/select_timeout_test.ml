open Golike_multicore_select

(** Use Io.sleep + buffered channel to build a timer that composes with
    Select.select.  The channel has capacity 1 so the timer fiber can
    always complete its send even if nobody receives. *)
let timeout_evt delay =
  let ch = Chan.make 1 in
  Sched.fork (fun () -> Io.sleep delay; Chan.send ch ());
  Chan.recv_evt ch

let test_timeout_wins () =
  Sched.run ~num_domains:4 (fun () ->
      let ch = Chan.make 0 in
      let winner =
        Select.select
          [ Chan.recv_evt ch |> Select.wrap (fun v -> `Msg v)
          ; timeout_evt 0.02 |> Select.wrap (fun () -> `Timeout)
          ]
      in
      match winner with
      | `Timeout -> ()
      | `Msg _ -> failwith "expected timeout")

let test_message_wins () =
  Sched.run ~num_domains:4 (fun () ->
      let ch = Chan.make 0 in
      Sched.fork (fun () ->
          Io.sleep 0.01;
          Chan.send ch 42);
      let winner =
        Select.select
          [ Chan.recv_evt ch |> Select.wrap (fun v -> `Msg v)
          ; timeout_evt 0.20 |> Select.wrap (fun () -> `Timeout)
          ]
      in
      match winner with
      | `Msg 42 -> ()
      | `Msg _ -> failwith "wrong payload"
      | `Timeout -> failwith "unexpected timeout")

let () =
  test_timeout_wins ();
  test_message_wins ();
  Printf.printf "select_timeout_test: PASSED\n%!"
