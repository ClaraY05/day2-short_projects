open! Core

type t =
  | Torch
  | Shield
[@@deriving sexp_of, compare, equal, enumerate]

let to_string = function Torch -> "torch" | Shield -> "shield"
