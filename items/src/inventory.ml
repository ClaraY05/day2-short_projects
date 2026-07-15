open! Core

let num_slots = 9

(* Only occupied slots appear as keys; a slot number is in [1 .. num_slots]. *)
type t = Item.t Map.M(Int).t [@@deriving sexp_of, compare, equal]

let empty = Map.empty (module Int)
let slot_numbers = List.range 1 (num_slots + 1)

let items t =
  Array.of_list (List.map slot_numbers ~f:(fun slot -> Map.find t slot))
;;

let is_full t = Map.length t >= num_slots

let add t item =
  match List.find slot_numbers ~f:(fun slot -> not (Map.mem t slot)) with
  | None -> Or_error.error_s [%message "inventory full"]
  | Some slot -> Ok (Map.set t ~key:slot ~data:item)
;;

let place t ~slot =
  match slot < 1 || slot > num_slots with
  | true -> Or_error.error_s [%message "no such slot" (slot : int)]
  | false ->
    (match Map.find t slot with
     | None -> Or_error.error_s [%message "slot is empty" (slot : int)]
     | Some item -> Ok (Map.remove t slot, item))
;;

let to_string_hum t =
  List.map slot_numbers ~f:(fun slot ->
    let contents =
      match Map.find t slot with
      | None -> "-"
      | Some item -> Item.to_string item
    in
    [%string "[%{slot#Int}:%{contents}]"])
  |> String.concat
;;
