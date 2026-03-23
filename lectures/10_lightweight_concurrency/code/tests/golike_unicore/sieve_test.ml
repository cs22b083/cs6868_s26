open Golike_unicore

(* Concurrent prime sieve
 *
 * The sieve works by building a pipeline of filter fibers connected by
 * channels. A generator fiber produces the sequence 2, 3, 4, 5, ...
 * The main fiber repeatedly reads the first value from the current channel
 * — which is guaranteed to be prime — then spawns a new filter fiber that
 * removes all multiples of that prime, forwarding survivors to the next
 * channel. The pipeline grows by one stage for each prime found:
 *
 * generate          filter(2)        filter(3)        filter(5)
 * 2,3,4,5,… ──ch0──▶ drop %2 ──ch1──▶ drop %3 ──ch2──▶ drop %5 ──ch3──▶ …
 *                        │                │                │
 *                     prime=2          prime=3          prime=5
 *
 * Step-by-step for the first few primes:
 *
 *   1. Main reads 2 from ch0              → 2 is prime
 *      Spawn filter(2): ch0 ──▶ [drop %2] ──▶ ch1
 *
 *   2. Main reads 3 from ch1              → 3 is prime
 *      Spawn filter(3): ch1 ──▶ [drop %3] ──▶ ch2
 *
 *   3. Main reads 5 from ch2 (4 was dropped by filter(2))
 *      Spawn filter(5): ch2 ──▶ [drop %5] ──▶ ch3
 *
 *   4. Main reads 7 from ch3 (6 was dropped by filter(2) and filter(3))
 *      …and so on.
 *)
let () =
  Printf.printf "=== Concurrent Prime Sieve ===\n";
  Sched.run (fun () ->
    let generate ch =
      let i = ref 2 in
      while true do
        Chan.send ch !i;
        incr i
      done
    in
    let filter in_ch out_ch prime =
      while true do
        let n = Chan.recv in_ch in
        if n mod prime <> 0 then
          Chan.send out_ch n
      done
    in
    let src = Chan.make 0 in
    Sched.fork (fun () -> generate src);
    let cur = ref src in
    for _ = 1 to 20 do
      let prime = Chan.recv !cur in
      Printf.printf "  %d\n" prime;
      let next = Chan.make 0 in
      let prev = !cur in
      Sched.fork (fun () -> filter prev next prime);
      cur := next
    done
  )
(* Output:
  === Concurrent Prime Sieve ===
    2
    3
    5
    7
    11
    13
    17
    19
    23
    29
    31
    37
    41
    43
    47
    53
    59
    61
    67
    71
*)
