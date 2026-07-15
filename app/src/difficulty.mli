(** Gameplay presets, straight from the Camel O design's difficulty knob.

    A difficulty picks the maze size, how many banana peels the truck
    spilled, the shape of the torch beam and which beast prowls the dunes.
    {!Flow.create} turns the chosen preset's {!type-config} into a
    {!Sandbox_engine.Game}.

    {[
      let config = Difficulty.config Nightmare in
      config.num_bananas = 24
    ]} *)

open! Core
open Sandbox_engine

type t =
  | Easy
  | Normal
  | Nightmare
[@@deriving sexp_of, compare, equal, enumerate]

(** The design's default. *)
val default : t

type config =
  { rows : int
  (** maze height in cells; odd, see {!Sandbox_engine.Maze.generate} *)
  ; cols : int (** maze width in cells; odd *)
  ; num_bananas : int (** peels spilled on the first maze *)
  ; cone_degrees : float (** torch beam half-angle *)
  ; view_cells : float (** torch beam reach, in cells *)
  ; monster : (module Monster.S) (** which beast chases the trader *)
  ; monster_cells_per_second : float
  (** how fast the frontend glides the beast between cells; the design's 2.7
      / 3.6 / 4.7 against the trader's 5.3 *)
  }

val config : t -> config

(** Extra beam while a {!Sandbox_engine.Maze.torches} pickup burns
    ({!Sandbox_engine.Game.torch_ticks_exn} > 0): the design widens the cone
    by 16 degrees and stretches the view by 3 cells. *)
val torch_cone_bonus_degrees : float

val torch_view_bonus_cells : float
