open! Core

type t = { position : Position.t } [@@deriving sexp_of, compare, equal]

let create position = { position }
let position t = t.position
let is_at t position = Position.equal t.position position
