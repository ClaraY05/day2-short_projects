(** A cell coordinate on the maze grid.

    Row [0] is the top row and column [0] the leftmost column, so moving
    "down" on screen increases [row]. Used by every other engine module; see
    {!Direction.step} for moving a position one cell. *)

open! Core

type t =
  { row : int
  ; col : int
  }
[@@deriving sexp_of, compare, equal, hash]

include Comparable.S_plain with type t := t

val create : row:int -> col:int -> t

(** [distance_squared a b] is the squared Euclidean distance between two
    cells, handy for circular masks, e.g.
    [distance_squared a b <= radius * radius]. *)
val distance_squared : t -> t -> int
