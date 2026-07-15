(** A compass direction the player (or a monster) can face.

    [North] is "up" on the grid, i.e. decreasing row. The map never rotates:
    facing only decides where the player moves next and where {!Lighting}
    points the torch beam. *)

open! Core

type t =
  | North
  | East
  | South
  | West
[@@deriving sexp_of, compare, equal, enumerate]

val turn_left : t -> t
val turn_right : t -> t
val turn_around : t -> t

(** [step position t] is the cell one move away in direction [t]. The result
    may be out of bounds or a wall; callers check with {!Maze.is_floor}. *)
val step : Position.t -> t -> Position.t
