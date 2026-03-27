open Golike_multicore_select

(** Demonstrates that [Io.read] does NOT block other fibers.

    Same setup as [blocking_io_demo]: Fiber 1 reads from a pipe that
    nobody writes to, Fiber 2 tries to print "tick" every scheduling round.

    But here Fiber 1 uses [Io.read] instead of [Unix.read].  The scheduler
    suspends Fiber 1 cooperatively (via poll), so Fiber 2 keeps running.

    Expected output:
      Fiber 2: tick 0
      Fiber 1: about to do non-blocking read (will suspend, not hang)...
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
      (* Fiber 2: cooperative ticker — yields between prints *)
      let rec ticker i =
        if i >= 5 then
          Printf.printf "Fiber 2: done — read never blocked us!\n%!"
        else begin
          Printf.printf "Fiber 2: tick %d\n%!" i;
          Sched.yield ();
          ticker (i + 1)
        end
      in
      ticker 0)
