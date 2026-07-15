open! Core
open Sandbox_items

let%expect_test "items are enumerable and have stable names" =
  List.iter Item.all ~f:(fun item -> print_endline (Item.to_string item));
  [%expect {|
    torch
    shield
    |}]
;;
