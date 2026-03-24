(** Concurrent prime sieve using select + IVar cancellation (multicore). *)

open Golike_multicore_select

exception Cancelled

(** [or_cancel cancel evt] synchronises on [evt], but raises {!Cancelled}
    if the [cancel] IVar is filled first. *)
let or_cancel cancel evt = Select.select [
  evt;
  Ivar.readEvt cancel |> Select.wrap (fun () -> raise Cancelled);
]

let () =
  Printf.printf "=== Prime sieve (select + IVar cancel) ===\n";
  let expected =
    [| 2; 3; 5; 7; 11; 13; 17; 19; 23; 29;
       31; 37; 41; 43; 47; 53; 59; 61; 67; 71 |]
  in
  let n_primes = 20 in
  let result = Array.make n_primes 0 in
  Sched.run ~num_domains:4 (fun () ->
    let cancel = Ivar.create () in

    let generate out_ch =
      try
        let i = ref 2 in
        while true do
          or_cancel cancel (Chan.sendEvt out_ch !i);
          incr i
        done
      with Cancelled -> ()
    in

    let filter in_ch out_ch prime =
      try
        while true do
          let n = or_cancel cancel (Chan.recvEvt in_ch) in
          if n mod prime <> 0 then
            or_cancel cancel (Chan.sendEvt out_ch n)
        done
      with Cancelled -> ()
    in

    let src = Chan.make 0 in
    Sched.fork (fun () -> generate src);
    let cur = ref src in
    for i = 0 to n_primes - 1 do
      let prime = Chan.recv !cur in
      result.(i) <- prime;
      Printf.printf "  %d\n" prime;
      let next = Chan.make 0 in
      let prev = !cur in
      Sched.fork (fun () -> filter prev next prime);
      cur := next
    done;
    Ivar.fill cancel ()
  );
  assert (result = expected);
  Printf.printf "  PASSED\n"
