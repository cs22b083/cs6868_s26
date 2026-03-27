open Golike_multicore_select

(** Same as [async_io_demo], but Fiber 2 uses [Io.sleep 1.0] instead of
    [Sched.yield].  Each tick is ~1 second apart, making the interleaving
    easy to observe in real time.

    Expected output (one tick per second):
      Fiber 1: about to do non-blocking read (will suspend, not hang)...
      Fiber 2: tick 0
      Fiber 2: tick 1
      Fiber 2: tick 2
      Fiber 2: tick 3
      Fiber 2: tick 4
      Fiber 2: done — read never blocked us! *)

let () =
  let rd, _wr = Unix.pipe () in   (* nobody writes to _wr *)
  Unix.set_nonblock rd;
  Sched.run ~num_domains:1 (fun () ->
      (* Fiber 1: non-blocking read — suspends without freezing the OS thread *)
      Sched.fork (fun () ->
          Printf.printf "Fiber 1: about to do non-blocking read (will suspend, not hang)...\n%!";
          let buf = Bytes.create 1024 in
          let n = Io.read rd buf 0 1024 in
          Printf.printf "Fiber 1: got %d bytes\n%!" n);
      (* Fiber 2: cooperative ticker — sleeps 1s between prints *)
      let rec ticker i =
        if i >= 5 then
          Printf.printf "Fiber 2: done — read never blocked us!\n%!"
        else begin
          Printf.printf "Fiber 2: tick %d\n%!" i;
          Io.sleep 1.0;
          ticker (i + 1)
        end
      in
      ticker 0)
