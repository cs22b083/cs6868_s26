(* Lecture 11: Comprehensions
   ===========================

   OxCaml adds list and array comprehensions — set-builder notation
   for constructing collections.

   Syntax:
     [ expr for pat in seq when cond ]         — list
     [| expr for pat in seq when cond |]       — array
     for var = lo to hi                        — range
     for x in xs and y in ys                   — parallel iteration
     for x in xs for y in ys                   — nested iteration
*)

(* --- 1. Basic list comprehension --- *)

let squares = [ x * x for x = 1 to 10 ]

let () =
  Printf.printf "squares: ";
  List.iter (Printf.printf "%d ") squares;
  Printf.printf "\n"

(* --- 2. Filtered comprehension --- *)

let even_squares = [ x * x for x = 1 to 20 when x mod 2 = 0 ]

let () =
  Printf.printf "even squares: ";
  List.iter (Printf.printf "%d ") even_squares;
  Printf.printf "\n"

(* --- 3. Array comprehension --- *)

let cubes = [| x * x * x for x = 1 to 10 |]

let () =
  Printf.printf "cubes: ";
  Array.iter (Printf.printf "%d ") cubes;
  Printf.printf "\n"

(* --- 4. Nested iteration (Cartesian product) --- *)

let pairs = [ (i, j) for i = 1 to 3 for j = 1 to 3 when i <> j ]

let () =
  Printf.printf "pairs: ";
  List.iter (fun (i, j) -> Printf.printf "(%d,%d) " i j) pairs;
  Printf.printf "\n"

(* --- 5. Iterating over lists --- *)

let names = ["Alice"; "Bob"; "Carol"]
let greetings = [ Printf.sprintf "Hello, %s!" name for name in names ]

let () =
  List.iter (Printf.printf "%s\n") greetings

(* --- 6. Parallel iteration (zip-like) --- *)

let xs = [1; 2; 3]
let ys = [10; 20; 30]
let sums = [ x + y for x in xs and y in ys ]

let () =
  Printf.printf "pairwise sums: ";
  List.iter (Printf.printf "%d ") sums;
  Printf.printf "\n"

(* --- 7. Practical: multiplication table --- *)

let mul_table n =
  [| [| i * j for j = 1 to n |] for i = 1 to n |]

let () =
  let t = mul_table 5 in
  Printf.printf "5x5 multiplication table:\n";
  Array.iter (fun row ->
    Array.iter (Printf.printf "%4d") row;
    Printf.printf "\n"
  ) t

(* --- 8. Flatten with nested for --- *)

let flat = [ (i, j) for i = 0 to 2 for j = 0 to i ]

let () =
  Printf.printf "triangular: ";
  List.iter (fun (i, j) -> Printf.printf "(%d,%d) " i j) flat;
  Printf.printf "\n"

(* --- 9. Sieve-like: primes up to n --- *)

let is_prime n =
  if n < 2 then false
  else
    let mutable ok = true in
    let mutable i = 2 in
    while i * i <= n && ok do
      if n mod i = 0 then ok <- false;
      i <- i + 1
    done;
    ok

let primes_up_to n = [ x for x = 2 to n when is_prime x ]

let () =
  let ps = primes_up_to 50 in
  Printf.printf "primes up to 50: ";
  List.iter (Printf.printf "%d ") ps;
  Printf.printf "\n"
