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

let run_server port =
  let fd = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.set_nonblock fd;
  Unix.setsockopt fd Unix.SO_REUSEADDR true;
  Unix.bind fd (Unix.ADDR_INET (Unix.inet_addr_loopback, port));
  Unix.listen fd 5;
  Printf.printf "echo server listening on port %d\n%!" port;
  Sched.run ~num_domains:4 (fun () ->
      let rec accept_loop () =
        let cfd, _addr = Io.accept fd in
        Sched.fork (fun () -> echo_handler cfd);
        accept_loop ()
      in
      accept_loop ())

let run_client port =
  Sched.run ~num_domains:1 (fun () ->
      let fd = Unix.socket ~cloexec:true Unix.PF_INET Unix.SOCK_STREAM 0 in
      Unix.set_nonblock fd;
      Io.connect fd (Unix.ADDR_INET (Unix.inet_addr_loopback, port));
      let buf = Bytes.create 1024 in
      let rec loop () =
        Printf.printf "> %!";
        let line = input_line stdin in
        let payload = Bytes.of_string line in
        ignore (Io.send fd payload 0 (Bytes.length payload) [] : int);
        let n = Io.recv fd buf 0 (Bytes.length buf) [] in
        if n > 0 then begin
          Printf.printf "%s\n%!" (Bytes.sub_string buf 0 n);
          loop ()
        end
      in
      (try loop () with End_of_file -> ());
      Unix.close fd)

let () =
  match Sys.argv with
  | [| _; "server"; port |] -> run_server (int_of_string port)
  | [| _; "client"; port |] -> run_client (int_of_string port)
  | _ ->
    Printf.eprintf "usage: %s server <port>\n       %s client <port>\n"
      Sys.argv.(0) Sys.argv.(0);
    exit 1
