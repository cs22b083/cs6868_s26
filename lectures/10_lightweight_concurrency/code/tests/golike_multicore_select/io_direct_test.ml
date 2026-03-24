open Golike_multicore_select

let send_all fd bytes =
  let len = Bytes.length bytes in
  let rec loop offset =
    if offset < len then begin
      let wrote = Io.send fd bytes offset (len - offset) [] in
      if wrote <= 0 then failwith "Io.send returned 0"
      else loop (offset + wrote)
    end
  in
  loop 0

let () =
  Sched.run ~num_domains:4 (fun () ->
      let left, right = Unix.socketpair Unix.PF_UNIX Unix.SOCK_STREAM 0 in
      Unix.set_nonblock left;
      Unix.set_nonblock right;
      let payload = Bytes.of_string "hello async" in
      Sched.fork (fun () ->
          Io.sleep 0.02;
          send_all left payload;
          Unix.close left);
      let buf = Bytes.create (Bytes.length payload) in
      let received = Io.recv right buf 0 (Bytes.length buf) [] in
      assert (received = Bytes.length payload);
      assert (Bytes.sub_string buf 0 received = "hello async");
      Unix.close right);
  Printf.printf "io_direct_test: PASSED\n%!"
