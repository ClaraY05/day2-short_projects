open! Core
open Sandbox_engine

type intent =
  | Move of Direction.t
  | Confirm
[@@deriving sexp_of, compare, equal]

let intent_of_key key =
  match String.lowercase key with
  | "w" | "arrowup" -> Some (Move North)
  | "s" | "arrowdown" -> Some (Move South)
  | "a" | "arrowleft" -> Some (Move West)
  | "d" | "arrowright" -> Some (Move East)
  | "enter" | " " -> Some Confirm
  | _ -> None
;;
