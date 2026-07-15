open! Core
open Sandbox_items

let add_exn inventory item = Or_error.ok_exn (Inventory.add inventory item)

let%expect_test "picking items up fills the lowest free slots" =
  print_endline (Inventory.to_string_hum Inventory.empty);
  [%expect {| [1:-][2:-][3:-][4:-][5:-][6:-][7:-][8:-][9:-] |}];
  let inventory = add_exn (add_exn Inventory.empty Item.Torch) Item.Shield in
  print_endline (Inventory.to_string_hum inventory);
  [%expect {| [1:torch][2:shield][3:-][4:-][5:-][6:-][7:-][8:-][9:-] |}]
;;

let%expect_test "pressing a slot number places its item and frees the slot" =
  let inventory = add_exn (add_exn Inventory.empty Item.Torch) Item.Shield in
  let inventory, item =
    Or_error.ok_exn (Inventory.place inventory ~slot:1)
  in
  print_s [%sexp (item : Item.t)];
  [%expect {| Torch |}];
  print_endline (Inventory.to_string_hum inventory);
  [%expect {| [1:-][2:shield][3:-][4:-][5:-][6:-][7:-][8:-][9:-] |}];
  (* The freed slot 1 is the lowest free one, so the next pickup lands there. *)
  let inventory = add_exn inventory Item.Torch in
  print_endline (Inventory.to_string_hum inventory);
  [%expect {| [1:torch][2:shield][3:-][4:-][5:-][6:-][7:-][8:-][9:-] |}]
;;

let%expect_test "placing an empty or out-of-range slot is an error" =
  print_s
    [%sexp
      (Inventory.place Inventory.empty ~slot:1
       : (Inventory.t * Item.t) Or_error.t)];
  [%expect {| (Error ("slot is empty" (slot 1))) |}];
  print_s
    [%sexp
      (Inventory.place Inventory.empty ~slot:0
       : (Inventory.t * Item.t) Or_error.t)];
  [%expect {| (Error ("no such slot" (slot 0))) |}];
  print_s
    [%sexp
      (Inventory.place Inventory.empty ~slot:10
       : (Inventory.t * Item.t) Or_error.t)];
  [%expect {| (Error ("no such slot" (slot 10))) |}]
;;

let%expect_test "the inventory holds nine items, then is full" =
  let full =
    List.init Inventory.num_slots ~f:(const Item.Torch)
    |> List.fold ~init:Inventory.empty ~f:add_exn
  in
  print_s [%sexp (Inventory.is_full full : bool)];
  [%expect {| true |}];
  print_s [%sexp (Inventory.add full Item.Shield : Inventory.t Or_error.t)];
  [%expect {| (Error "inventory full") |}]
;;
