(** The player's point of view: a rotated, torch-lit window on the maze.

    The world is drawn from above, but relative to the player: the grid is
    rotated so the direction the player faces is always up, the player sits
    in the center, and only cells inside a circle of [radius] are visible —
    everything else is darkness. The renderer in [sandbox.app] draws exactly
    this grid.

    {[
      let tiles =
        Viewport.view
          ~maze
          ~player
          ~facing:East
          ~monster:(Some monster_position)
          ~radius:4
      in
      tiles.(4).(4) = Some Viewport.Tile.Player
    ]} *)

open! Core

module Tile : sig
  type t =
    | Player (** always the center cell, always facing up *)
    | Wall
    | Floor
    | Banana
    | Key
    | Monster
  [@@deriving sexp_of, compare, equal]
end

(** [view ~maze ~player ~facing ~monster ~radius] is a square grid of side
    [2 * radius + 1]. [None] marks darkness: cells outside the light circle
    or beyond the edge of the maze. Row [0] is what lies ahead of the player. *)
val view
  :  maze:Maze.t
  -> player:Position.t
  -> facing:Direction.t
  -> monster:Position.t option
  -> radius:int
  -> Tile.t option array array

(** [full_map ~maze ~player ~monster] is the whole grid drawn from above with
    no rotation and no light mask: row [0] is the top of the maze, every cell
    is a [Some], and nothing is hidden. Unlike {!view} this ignores which way
    the player faces. The map-view executable (see [sandbox.app]) uses it to
    watch the maze regenerate; the real game uses {!view}. *)
val full_map
  :  maze:Maze.t
  -> player:Position.t
  -> monster:Position.t option
  -> Tile.t option array array
