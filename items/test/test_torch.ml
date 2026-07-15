open! Core
open Sandbox_items
open Sandbox_engine

let%expect_test "a torch sits on a cell and becomes a torch item" =
  let torch = Torch.create (Position.create ~row:2 ~col:5) in
  print_s [%sexp (Torch.position torch : Position.t)];
  [%expect {| ((row 2) (col 5)) |}];
  print_s [%sexp (Torch.is_at torch (Position.create ~row:2 ~col:5) : bool)];
  [%expect {| true |}];
  print_s [%sexp (Torch.is_at torch (Position.create ~row:0 ~col:0) : bool)];
  [%expect {| false |}];
  print_s [%sexp (Torch.as_item torch : Item.t)];
  [%expect {| Torch |}]
;;
