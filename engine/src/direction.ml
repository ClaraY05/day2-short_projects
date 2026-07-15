open! Core

type t =
  | North
  | East
  | South
  | West
[@@deriving sexp_of, compare, equal, enumerate]

let turn_right = function
  | North -> East
  | East -> South
  | South -> West
  | West -> North
;;

let turn_left = function
  | North -> West
  | West -> South
  | South -> East
  | East -> North
;;

let turn_around t = turn_right (turn_right t)

let step ({ Position.row; col } : Position.t) t : Position.t =
  match t with
  | North -> { row = row - 1; col }
  | South -> { row = row + 1; col }
  | East -> { row; col = col + 1 }
  | West -> { row; col = col - 1 }
;;
