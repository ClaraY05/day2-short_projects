open! Core

module T = struct
  type t =
    { row : int
    ; col : int
    }
  [@@deriving sexp_of, compare, equal, hash]
end

include T
include Comparable.Make_plain (T)

let create ~row ~col = { row; col }

let distance_squared a b =
  let dr = a.row - b.row in
  let dc = a.col - b.col in
  (dr * dr) + (dc * dc)
;;
