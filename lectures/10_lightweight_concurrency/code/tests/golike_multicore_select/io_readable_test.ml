open Golike_multicore_select

let () =
  Sched.run ~num_domains:4 (fun () ->
      let rfd, wfd = Unix.pipe () in
      Sched.fork (fun () ->
          Io.sleep 0.02;
          ignore (Unix.write_substring wfd "x" 0 1 : int));
      let buf = Bytes.create 1 in
      let n = Io.read rfd buf 0 1 in
      assert (n = 1);
      assert (Bytes.get buf 0 = 'x');
      Unix.close rfd;
      Unix.close wfd);
  Printf.printf "io_readable_test: PASSED\n%!"
