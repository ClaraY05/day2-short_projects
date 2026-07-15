open! Core

type t = { torches : int } [@@deriving sexp_of, compare, equal]

let empty = { torches = 0 }
let torches t = t.torches
let has_torch t = t.torches > 0
let add_torch t = { torches = t.torches + 1 }

let remove_torch t =
  match t.torches with
  | 0 -> Or_error.error_s [%message "no torch to place"]
  | n -> Ok { torches = n - 1 }
;;

let to_string_hum t =
  let torches = t.torches in
  [%string "Torches: %{torches#Int}"]
;;
