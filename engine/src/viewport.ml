open! Core

module Tile = struct
  type t =
    | Player
    | Wall
    | Floor
    | Banana
    | Key
    | Monster
  [@@deriving sexp_of, compare, equal]
end

(* Maps an offset in view space — where "up" is whatever direction the player
   faces — to an offset in world space. *)
let rotate_to_world (facing : Direction.t) ~view_row ~view_col =
  match facing with
  | North -> view_row, view_col
  | East -> view_col, -view_row
  | South -> -view_row, -view_col
  | West -> -view_col, view_row
;;

let view ~maze ~player ~facing ~monster ~radius =
  let side = (2 * radius) + 1 in
  Array.init side ~f:(fun i ->
    Array.init side ~f:(fun j ->
      let view_row = i - radius in
      let view_col = j - radius in
      if (view_row * view_row) + (view_col * view_col) > radius * radius
      then None
      else (
        let world_row, world_col =
          rotate_to_world facing ~view_row ~view_col
        in
        let position =
          Position.create
            ~row:(player.Position.row + world_row)
            ~col:(player.Position.col + world_col)
        in
        let monster_here =
          match monster with
          | Some monster -> Position.equal monster position
          | None -> false
        in
        if view_row = 0 && view_col = 0
        then Some Tile.Player
        else if not (Maze.in_bounds maze position)
        then None
        else if monster_here
        then Some Tile.Monster
        else if Position.equal position (Maze.key maze)
        then Some Tile.Key
        else if Maze.is_banana maze position
        then Some Tile.Banana
        else if Maze.is_wall maze position
        then Some Tile.Wall
        else Some Tile.Floor)))
;;
