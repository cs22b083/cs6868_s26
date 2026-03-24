open Golike_multicore_select

let () =
  Sched.run ~num_domains:1 (fun () ->
      Printf.printf "main: before sleep\n%!";
      Io.sleep 0.1;
      Printf.printf "main: after sleep\n%!")
