(******************************************************************************)
(* Value Representation in OCaml using Obj                                     *)
(*                                                                            *)
(* This file is intentionally written in a literate style with many comments. *)
(* It is meant for classroom demonstration, especially for explaining why      *)
(* CAS on a list behaves the way it does.                                      *)
(*                                                                            *)
(* Run:                                                                        *)
(*   ocaml value_representation_with_obj.ml                                    *)
(* or                                                                           *)
(*   ocamlopt -o value_repr_demo value_representation_with_obj.ml && ./value_repr_demo *)
(*                                                                            *)
(* Tested with OCaml 5.4.0.                                                   *)
(*                                                                            *)
(* WARNING: Obj is intentionally unsafe and breaks type abstraction.           *)
(* Use this only for learning, debugging, and runtime-internals exploration.  *)
(*                                                                            *)
(* Student quick-start:                                                       *)
(* 1) Run the file and read sections in order:                                *)
(*      ocaml value_representation_with_obj.ml                                *)
(* 2) Pick one value (for example [1] or Some 42) and match:                 *)
(*      - immediate vs boxed                                                  *)
(*      - tag and size                                                        *)
(*      - nested fields                                                       *)
(* 3) Then read the CAS sections and connect the result to representation.    *)
(* 4) Optional: edit/add values near "Part 3" and re-run.                    *)
(*                                                                            *)
(* Important runtime model (for boxed values):                                *)
(*                                                                            *)
(*   +------------------+--------------------------------------------------+  *)
(*   | header word      | fields[0], fields[1], ..., fields[size-1]       |  *)
(*   +------------------+--------------------------------------------------+  *)
(*            |                          |                                     *)
(*            |                          +-- payload words                     *)
(*            +-- contains at least:                                           *)
(*                - size: number of fields                                     *)
(*                - tag: block kind (tuple/cons/string/double/closure/...)    *)
(*                - GC metadata (color/flags bits used by the runtime)         *)
(*                                                                            *)
(* Obj.size and Obj.tag expose the size/tag view of that header.              *)
(******************************************************************************)

(*
   ---------------------------------------------------------------------------
   Part 1. A tiny inspector for runtime values
   ---------------------------------------------------------------------------

   OCaml values are represented as either:
   1) Immediate values (stored directly in one machine word), or
   2) Heap blocks (a pointer to a block with a header and fields).

   Obj.repr converts any value to Obj.t so we can inspect it.
   Obj.is_int tells us if this Obj.t is immediate.

   For immediate values, Obj.magic can reinterpret that word as an int and
   print it. For heap blocks, Obj.tag and Obj.size describe the block layout.
*)

let rec dump_obj ?(indent = 0) (v : Obj.t) : unit =
  let pad = String.make indent ' ' in
  if Obj.is_int v then (
    (* Obj.magic is an unchecked cast -- no runtime conversion, just reinterprets the word *)
    let n : int = Obj.magic v in
    Printf.printf "%s- immediate word (Obj.is_int = true), decoded int view = %d\n" pad n)
  else (
    let tag = Obj.tag v in
    let size = Obj.size v in
    Printf.printf "%s- heap block (Obj.is_int = false), tag = %d, size = %d\n" pad tag size;
    if tag >= Obj.no_scan_tag then
      Printf.printf
        "%s  (tag >= Obj.no_scan_tag, payload is raw bytes/non-values; not traversing)\n"
        pad
    else
      for i = 0 to size - 1 do
        Printf.printf "%s  field[%d]:\n" pad i;
        dump_obj ~indent:(indent + 4) (Obj.field v i)
      done)

let section title =
  Printf.printf "\n%s\n%s\n" title (String.make (String.length title) '=')

let inspect name x =
  Printf.printf "\n%s\n" name;
  dump_obj (Obj.repr x)

let immediate_int_view (v : Obj.t) : int option =
  if Obj.is_int v then Some (Obj.magic v : int) else None

let summary_row name x =
  let v = Obj.repr x in
  if Obj.is_int v then
    let decoded : int = Obj.magic v in
    Printf.printf "%-28s | %-5s | %-4s | %-4s | %d\n" name "yes" "-" "-" decoded
  else
    Printf.printf
      "%-28s | %-5s | %-4d | %-4d | %s\n"
      name
      "no"
      (Obj.tag v)
      (Obj.size v)
      "-"

let explain_header_for name x =
  let v = Obj.repr x in
  Printf.printf "\n%s\n" name;
  if Obj.is_int v then
    Printf.printf "  immediate value: no heap header, no fields\n"
  else
    let tag = Obj.tag v in
    let size = Obj.size v in
    Printf.printf "  boxed value: points to a heap block\n";
    Printf.printf "  header-derived view: tag=%d size=%d\n" tag size;
    if tag >= Obj.no_scan_tag then
      Printf.printf
        "  tag >= Obj.no_scan_tag: payload treated as raw bytes/non-pointers\n"
    else
      Printf.printf "  tag < Obj.no_scan_tag: payload fields are traversable values\n"

(*
   ---------------------------------------------------------------------------
   Part 2. A safer helper for immediate encoding intuition
   ---------------------------------------------------------------------------

   For OCaml immediate integers, runtime encoding is often described as:
     encoded_word = (n << 1) | 1

   We avoid unsafe reinterpretation tricks here and just compute the expected
   encoded pattern arithmetically for demonstration.
*)

let show_expected_encoded_word_for_int name n =
  let encoded = (n lsl 1) lor 1 in
  Printf.printf "%s: integer %d has expected encoded word pattern %d\n" name n encoded

(*
   ---------------------------------------------------------------------------
   Part 3. Sample values to inspect
   ---------------------------------------------------------------------------
*)

type traffic = Red | Yellow | Green

type payload = Payload of int

let int_val = 10
let float_val = 1.0
let bool_val = true
let unit_val = ()
let none_val : int option = None
let some_val : int option = Some 42
let red = Red
let yellow = Yellow
let green = Green
let payload_val = Payload 99
let empty_list = []
let non_empty_list = [ 1 ]
let longer_list = [ 1; 2; 3 ]
let tuple_val = (7, true)
let string_val = "ocaml"
let ref_to_an_int = ref int_val
let ref_to_an_empty_list = ref empty_list
let ref_to_a_non_empty_list = ref non_empty_list

(*
   ---------------------------------------------------------------------------
   Part 4. Why this matters for CAS on list
   ---------------------------------------------------------------------------

   CAS compares machine values.

   Immediate values:
   - CAS sees the word itself (e.g. ints, bool, []).

   Boxed heap values:
   - CAS compares physical equality (==, pointer identity), not structural equality (=).

   So two separately allocated lists [1] and [1] are structurally equal (=)
   but not physically identical (==). CAS on Atomic.t with expected = first list
   fails if the current cell contains the second list.
*)

let cas_demo_on_lists () =
  section "CAS behavior with lists";

  let l1 = [ 1 ] in
  let l2 = [ 1 ] in

  Printf.printf "l1 = l2  (structural equality) = %b\n" (l1 = l2);
  Printf.printf "l1 == l2 (physical equality)   = %b\n" (l1 == l2);

  let a = Atomic.make l1 in

  let cas_with_same_pointer = Atomic.compare_and_set a l1 [] in
  Printf.printf "CAS expected l1 when cell holds l1: %b\n" cas_with_same_pointer;

  Atomic.set a l1;

  let cas_with_equal_but_distinct_pointer = Atomic.compare_and_set a l2 [] in
  Printf.printf
    "CAS expected l2 when cell holds l1 (same shape, different allocation): %b\n"
    cas_with_equal_but_distinct_pointer;

  (* Empty list is immediate, so all [] are the same immediate value. *)
  Atomic.set a [];
  let cas_on_empty_list = Atomic.compare_and_set a [] [ 42 ] in
  Printf.printf "CAS expected [] when cell holds []: %b\n" cas_on_empty_list

let cas_demo_on_options () =
  section "CAS behavior with options";

  let a = Atomic.make None in
  let none_to_some = Atomic.compare_and_set a None (Some 1) in
  Printf.printf "CAS None -> Some 1 when cell holds None: %b\n" none_to_some;

  let s1 = Some 1 in
  let s2 = Some 1 in
  Atomic.set a s1;
  Printf.printf "s1 = s2  (structural equality) = %b\n" (s1 = s2);
  Printf.printf "s1 == s2 (physical equality)   = %b\n" (s1 == s2);

  let cas_same_pointer = Atomic.compare_and_set a s1 None in
  Printf.printf "CAS expected s1 when cell holds s1: %b\n" cas_same_pointer;

  Atomic.set a s1;
  let cas_equal_but_distinct = Atomic.compare_and_set a s2 None in
  Printf.printf "CAS expected s2 when cell holds s1: %b\n" cas_equal_but_distinct

let print_summary_table () =
  section "Compact summary table";
  Printf.printf "%-28s | %-5s | %-4s | %-4s | %s\n" "name" "imm?" "tag" "size" "decoded-int";
  Printf.printf "%s\n" (String.make 74 '-');
  summary_row "int 10" int_val;
  summary_row "float 1.0" float_val;
  summary_row "bool true" bool_val;
  summary_row "unit ()" unit_val;
  summary_row "None" none_val;
  summary_row "Some 42" some_val;
  summary_row "Red" red;
  summary_row "Yellow" yellow;
  summary_row "Green" green;
  summary_row "Payload 99" payload_val;
  summary_row "[]" empty_list;
  summary_row "[1]" non_empty_list;
  summary_row "[1;2;3]" longer_list;
  summary_row "(7,true)" tuple_val;
  summary_row "\"ocaml\"" string_val;
  summary_row "ref 10" ref_to_an_int;
  summary_row "ref [1]" ref_to_a_non_empty_list;
  Printf.printf "\nNote: ref and Atomic.t share the same runtime representation\n";
  Printf.printf "(single-field boxed block, tag 0). Atomic.t exists to provide\n";
  Printf.printf "memory-ordering guarantees, not a different representation.\n"

let print_memory_model_notes () =
  section "Memory model notes (header and fields)";
  Printf.printf
    "For boxed values, think in two pieces: one header word + N payload fields.\n";
  Printf.printf
    "Obj.size reports N (the number of payload fields), Obj.tag reports the block kind.\n";
  Printf.printf
    "The runtime header also packs GC metadata bits; Obj does not expose them directly.\n";
  Printf.printf
    "Obj.no_scan_tag = %d marks non-scannable payload blocks (e.g. strings, doubles).\n"
    Obj.no_scan_tag;

  explain_header_for "example: [1] (a cons cell)" non_empty_list;
  explain_header_for "example: Some 42" some_val;
  explain_header_for "example: \"ocaml\"" string_val;
  explain_header_for "example: 10" int_val

let print_how_to_use () =
  section "How to use this file";
  Printf.printf "1) Run: ocaml value_representation_with_obj.ml\n";
  Printf.printf "2) Read sections in order (representation -> memory model -> CAS).\n";
  Printf.printf "3) For each value, ask: immediate or boxed? if boxed, what tag/size?\n";
  Printf.printf
    "4) Modify/add values in Part 3, then rerun and predict output before seeing it.\n";
  Printf.printf
    "5) In CAS sections, compare (=) vs (==) and relate success/failure to identity.\n"

let () =
  print_how_to_use ();

  section "Representation walkthrough via Obj";

  inspect "int_val = 10" int_val;
  inspect "float_val = 1.0" float_val;
  inspect "bool_val = true" bool_val;
  inspect "unit_val = ()" unit_val;
  inspect "none_val : int option = None" none_val;
  inspect "some_val : int option = Some 42" some_val;
  inspect "red : traffic = Red" red;
  inspect "yellow : traffic = Yellow" yellow;
  inspect "green : traffic = Green" green;
  inspect "payload_val = Payload 99" payload_val;
  inspect "empty_list = []" empty_list;
  inspect "non_empty_list = [1]" non_empty_list;
  inspect "longer_list = [1;2;3]" longer_list;
  inspect "tuple_val = (7, true)" tuple_val;
  inspect "string_val = \"ocaml\"" string_val;
  inspect "ref_to_an_int = ref int_val" ref_to_an_int;
  inspect "ref_to_an_empty_list = ref []" ref_to_an_empty_list;
  inspect "ref_to_a_non_empty_list = ref [1]" ref_to_a_non_empty_list;

  section "Immediate encoding intuition";
  show_expected_encoded_word_for_int "int 10" int_val;
  (match immediate_int_view (Obj.repr bool_val) with
  | Some n -> show_expected_encoded_word_for_int "bool true (decoded int view)" n
  | None -> ());
  (match immediate_int_view (Obj.repr empty_list) with
  | Some n -> show_expected_encoded_word_for_int "empty list [] (decoded int view)" n
  | None -> ());
  (match immediate_int_view (Obj.repr none_val) with
  | Some n -> show_expected_encoded_word_for_int "None (decoded int view)" n
  | None -> ());
  (match immediate_int_view (Obj.repr red), immediate_int_view (Obj.repr yellow), immediate_int_view (Obj.repr green) with
  | Some r, Some y, Some g ->
      Printf.printf "traffic constructors decoded int views: Red=%d Yellow=%d Green=%d\n" r y g
  | _ -> ());
  Printf.printf "float 1.0 is boxed, so this immediate formula does not apply\n";

  section "A few notable constants from Obj";
  Printf.printf "Obj.double_tag = %d (used for boxed float blocks)\n" Obj.double_tag;
  Printf.printf "Obj.string_tag = %d (used for string/bytes-like data)\n" Obj.string_tag;
  Printf.printf "Obj.closure_tag = %d (used for closures)\n" Obj.closure_tag;

  cas_demo_on_lists ();
  cas_demo_on_options ();
  print_memory_model_notes ();
  print_summary_table ();

  section "Takeaway";
  Printf.printf
    "For Atomic.compare_and_set on polymorphic values:\n\
    - immediates compare by word value,\n\
    - heap blocks compare by physical equality (==), not structural equality (=).\n\
    This is exactly why CAS on list nodes uses pointer identity, not structural comparison.\n"
