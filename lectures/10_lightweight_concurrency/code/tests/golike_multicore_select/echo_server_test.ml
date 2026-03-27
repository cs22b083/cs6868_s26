open Golike_multicore_select

let echo_handler cfd =
  let buf = Bytes.create 1024 in
  let rec loop () =
    let n = Io.recv cfd buf 0 (Bytes.length buf) [] in
    if n > 0 then begin
      let rec send_all off rem =
        if rem > 0 then
          let w = Io.send cfd buf off rem [] in
          send_all (off + w) (rem - w)
      in
      send_all 0 n;
      loop ()
    end
  in
  (try loop () with Unix.Unix_error _ -> ());
  Unix.close cfd

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

let recv_exact fd buf off len =
  let rec loop off rem =
    if rem > 0 then
      let n = Io.recv fd buf off rem [] in
      if n = 0 then failwith "unexpected EOF"
      else loop (off + n) (rem - n)
  in
  loop off len

(** Single-client echo: send a message, receive the echo, verify. *)
let test_single_echo () =
  Sched.run ~num_domains:4 (fun () ->
      let server, port = make_server () in
      Sched.fork (fun () ->
          let cfd, _addr = Io.accept server in
          echo_handler cfd;
          Unix.close server);
      let client = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
      Unix.set_nonblock client;
      Io.connect client (Unix.ADDR_INET (Unix.inet_addr_loopback, port));
      let msg = "hello echo" in
      let payload = Bytes.of_string msg in
      ignore (Io.send client payload 0 (Bytes.length payload) [] : int);
      let buf = Bytes.create 64 in
      recv_exact client buf 0 (String.length msg);
      assert (Bytes.sub_string buf 0 (String.length msg) = msg);
      Unix.close client)

(** Multi-client echo: two clients connect concurrently, both get echoes. *)
let test_multi_client_echo () =
  Sched.run ~num_domains:4 (fun () ->
      let server, port = make_server () in
      let done_ch = Chan.make 0 in
      Sched.fork (fun () ->
          for _ = 1 to 2 do
            let cfd, _addr = Io.accept server in
            Sched.fork (fun () -> echo_handler cfd)
          done;
          Chan.recv done_ch; Chan.recv done_ch;
          Unix.close server);
      let run_client id =
        let client = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
        Unix.set_nonblock client;
        Io.connect client (Unix.ADDR_INET (Unix.inet_addr_loopback, port));
        let msg = Printf.sprintf "client%d" id in
        let payload = Bytes.of_string msg in
        ignore (Io.send client payload 0 (Bytes.length payload) [] : int);
        let buf = Bytes.create 64 in
        recv_exact client buf 0 (String.length msg);
        assert (Bytes.sub_string buf 0 (String.length msg) = msg);
        Unix.close client;
        Chan.send done_ch ()
      in
      Sched.fork (fun () -> run_client 1);
      run_client 2)

let () =
  test_single_echo ();
  test_multi_client_echo ();
  Printf.printf "echo_server_test: PASSED\n%!"
