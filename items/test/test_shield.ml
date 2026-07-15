open! Core
open Sandbox_items
open Sandbox_engine

let%expect_test "a shield sits on a cell and becomes a shield item" =
  let shield = Shield.create (Position.create ~row:1 ~col:3) in
  print_s [%sexp (Shield.position shield : Position.t)];
  [%expect {| ((row 1) (col 3)) |}];
  print_s
    [%sexp (Shield.is_at shield (Position.create ~row:1 ~col:3) : bool)];
  [%expect {| true |}];
  print_s [%sexp (Shield.as_item shield : Item.t)];
  [%expect {| Shield |}]
;;
