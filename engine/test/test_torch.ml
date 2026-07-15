open! Core
open Sandbox_engine

let%expect_test "a torch knows the cell it sits on" =
  let torch = Torch.create (Position.create ~row:2 ~col:5) in
  print_s [%sexp (Torch.position torch : Position.t)];
  [%expect {| ((row 2) (col 5)) |}];
  print_s [%sexp (Torch.is_at torch (Position.create ~row:2 ~col:5) : bool)];
  [%expect {| true |}];
  print_s [%sexp (Torch.is_at torch (Position.create ~row:0 ~col:0) : bool)];
  [%expect {| false |}]
;;
