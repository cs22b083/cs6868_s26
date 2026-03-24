open Golike_multicore_select

let make_server () =
  let fd = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.set_nonblock fd;
  Unix.setsockopt fd Unix.SO_REUSEADDR true;
  Unix.bind fd (Unix.ADDR_INET (Unix.inet_addr_loopback, 0));
  Unix.listen fd 5;
  let port =
    match Unix.getsockname fd with
    | Unix.ADDR_INET (_, p) -> p
    | _ -> assert false
  in
  (fd, port)

(** Test direct-style [Io.accept]. *)
let test_accept () =
  Sched.run ~num_domains:4 (fun () ->
      let server, port = make_server () in
      Sched.fork (fun () ->
          Io.sleep 0.01;
          let client = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
          Unix.set_nonblock client;
          Io.connect client (Unix.ADDR_INET (Unix.inet_addr_loopback, port));
          ignore (Io.send client (Bytes.of_string "hi") 0 2 [] : int);
          Unix.close client);
      let cfd, _addr = Io.accept server in
      let buf = Bytes.create 2 in
      let n = Io.recv cfd buf 0 2 [] in
      assert (n = 2);
      assert (Bytes.sub_string buf 0 n = "hi");
      Unix.close cfd;
      Unix.close server)

(** Test accept with a timeout using Io.sleep + channel composition. *)
let test_accept_timeout () =
  Sched.run ~num_domains:4 (fun () ->
      let server, _port = make_server () in
      let result_ch = Chan.make 0 in
      (* Fiber that tries to accept; may fail when server socket is closed *)
      Sched.fork (fun () ->
          (try
             let cfd, _addr = Io.accept server in
             Chan.send result_ch (`Accepted cfd)
           with Unix.Unix_error _ -> ()));
      (* Fiber that sends a timeout *)
      Sched.fork (fun () ->
          Io.sleep 0.02;
          Chan.send result_ch `Timeout);
      let result =
        Select.select
          [ Chan.recvEvt result_ch ]
      in
      (match result with
       | `Timeout -> ()
       | `Accepted cfd -> Unix.close cfd; failwith "expected timeout");
      Unix.close server)

let () =
  test_accept ();
  test_accept_timeout ();
  Printf.printf "accept_test: PASSED\n%!"
