(** Torch-beam brightness for the static top-down view.

    The map never rotates; instead the player carries a torch whose beam is a
    cone pointing where they face, plus a dim ambient glow ring around them.
    A cell is lit by the beam only if it is inside the cone, close enough,
    and no wall stands between it and the player.

    Positions are continuous, in cell units — the center of cell [(row, col)]
    is [(row +. 0.5, col +. 0.5)] — so a frontend animating the player
    between two cells can light the world from the in-between point and the
    beam sweeps smoothly.

    {[
      let b =
        Lighting.brightness
          ~maze
          ~player_row:1.5 (* center of row 1 *)
          ~player_col:1.5 (* center of col 1 *)
          ~facing:East
          ~cone_degrees:40.
          ~view_cells:6.
          ~cell:(Position.create ~row:1 ~col:4)
      in
      Float.( > ) b 0.
    ]}

    {!Game.torch_ticks_exn} tells the frontend when to pass a wider cone and
    a longer view. *)

open! Core

(** [brightness ~maze ~player_row ~player_col ~facing ~cone_degrees ~view_cells ~cell]
    is how lit [cell] is, from [0.] (darkness) to [1.] (full light).
    [cone_degrees] is the beam's half-angle and [view_cells] its reach in
    cell units. *)
val brightness
  :  maze:Maze.t
  -> player_row:float
  -> player_col:float
  -> facing:Direction.t
  -> cone_degrees:float
  -> view_cells:float
  -> cell:Position.t
  -> float

(** [line_of_sight ~maze ~from_row ~from_col ~cell] is whether a straight ray
    from the given point to the center of [cell] crosses no wall cell (other
    than [cell] itself, so walls facing the player count as visible). *)
val line_of_sight
  :  maze:Maze.t
  -> from_row:float
  -> from_col:float
  -> cell:Position.t
  -> bool
