open! Core
open Sandbox_engine

let%expect_test "picking up and placing torches" =
  let inventory = Inventory.empty in
  print_s [%sexp (Inventory.torches inventory : int)];
  [%expect {| 0 |}];
  print_s [%sexp (Inventory.has_torch inventory : bool)];
  [%expect {| false |}];
  let inventory = Inventory.add_torch (Inventory.add_torch inventory) in
  print_s [%sexp (Inventory.torches inventory : int)];
  [%expect {| 2 |}];
  print_endline (Inventory.to_string_hum inventory);
  [%expect {| Torches: 2 |}];
  let inventory = Or_error.ok_exn (Inventory.remove_torch inventory) in
  print_endline (Inventory.to_string_hum inventory);
  [%expect {| Torches: 1 |}]
;;

let%expect_test "placing with an empty inventory is an error" =
  print_s
    [%sexp (Inventory.remove_torch Inventory.empty : Inventory.t Or_error.t)];
  [%expect {| (Error "no torch to place") |}]
;;
