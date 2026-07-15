(** The dunes at night: the maze as the torch beam reveals it.

    The map never rotates and the camera glides with the trader; facing only
    swings the beam ({!Sandbox_engine.Lighting}). Corridors are drawn the
    mockup's way — dark floor outlined by amber wall strips — with dots,
    torches, banana peels, camel O, and the beast fading in with brightness
    or with the red "it is close" sense. Entity positions are continuous cell
    coordinates so {!Game_canvas} can animate the turn-based steps. *)

open! Core
open Sandbox_engine

(** Where a sprite currently stands, in cell units ([row +. 0.5] is the
    center of [row]), and whether it is mid-step. *)
type entity =
  { row : float
  ; col : float
  ; moving : bool
  }

val draw
  :  ctx:Canvas2d.t
  -> now_ms:float
  -> random_state:Random.State.t (** torch flicker jitter *)
  -> maze:Maze.t
  -> player:entity
  -> facing:Direction.t
  -> monster:entity
  -> cone_degrees:float (** beam half-angle, torch boost included *)
  -> view_cells:float (** beam reach, torch boost included *)
  -> unit

(** [draw_map] is the map-view counterpart of {!draw}: the whole maze scaled
    to fit the canvas and lit end to end — no torch cone, darkness or
    vignette — for watching it reshuffle when the trader slips on a banana.
    Same continuous entity coordinates as {!draw}; it just pulls the camera
    all the way out. *)
val draw_map
  :  ctx:Canvas2d.t
  -> now_ms:float
  -> maze:Maze.t
  -> player:entity
  -> facing:Direction.t
  -> monster:entity
  -> unit
