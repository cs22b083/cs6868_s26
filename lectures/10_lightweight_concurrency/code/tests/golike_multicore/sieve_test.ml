open Golike_multicore

(* Concurrent prime sieve
 *
 * Unlike the unicore version (which uses infinite loops and exits when
 * the run queue is empty), the multicore scheduler tracks active fibers
 * and waits for all to complete. The generator sends [Some n] for each
 * candidate and [None] as a quit message. Each filter stage forwards
 * [None] downstream before exiting, so the shutdown propagates through
 * the entire pipeline. *)
let () =
  Printf.printf "=== Concurrent Prime Sieve ===\n";
  let expected =
    [| 2; 3; 5; 7; 11; 13; 17; 19; 23; 29;
       31; 37; 41; 43; 47; 53; 59; 61; 67; 71 |]
  in
  let n_primes = 20 in
  let limit = 80 in (* 71 is the 20th prime; generate a bit beyond *)
  let result = Array.make n_primes 0 in
  Sched.run ~num_domains:4 (fun () ->
    let generate ch =
      for i = 2 to limit do
        Chan.send ch (Some i)
      done;
      Chan.send ch None
    in
    let filter in_ch out_ch prime =
      let running = ref true in
      while !running do
        match Chan.recv in_ch with
        | None ->
            Chan.send out_ch None;
            running := false
        | Some n ->
            if n mod prime <> 0 then
              Chan.send out_ch (Some n)
      done
    in
    let src = Chan.make 0 in
    Sched.fork (fun () -> generate src);
    let cur = ref src in
    for i = 0 to n_primes - 1 do
      let prime = match Chan.recv !cur with
        | Some p -> p
        | None -> assert false
      in
      result.(i) <- prime;
      Printf.printf "  %d\n" prime;
      let next = Chan.make 0 in
      let prev = !cur in
      Sched.fork (fun () -> filter prev next prime);
      cur := next
    done;
    (* Drain the last channel so the pipeline can shut down *)
    let rec drain () = match Chan.recv !cur with
      | None -> ()
      | Some _ -> drain ()
    in
    drain ()
  );
  assert (result = expected);
  Printf.printf "  PASSED\n"
