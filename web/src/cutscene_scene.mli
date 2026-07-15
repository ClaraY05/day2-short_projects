(** The three full-screen cutscenes, frame by frame.

    Each is a timed port of its Claude-design mockup: the banana-slip
    pratfall (walk, spin, flash, "you slipped...", tiles scrambling in), the
    jumpscare (heartbeat vignette, eyes in the dark, the strobing beast,
    "MAULED"), and the dawn reunion with camel O. {!Game_canvas} owns the
    clock: it calls {!draw} with the seconds since the cutscene began and
    ends the scene after {!Sandbox_app.Cutscene.duration_seconds}. *)

open! Core
open Sandbox_app

(** Pre-rolled randomness (tile scramble order, dawn sparkles), rolled once
    per app run so replays shimmer but do not reshuffle mid-scene. *)
type support

val support : random_state:Random.State.t -> support

val draw
  :  ctx:Canvas2d.t
  -> event:Cutscene.Event.t
  -> t_seconds:float
  -> now_ms:float
  -> random_state:Random.State.t (** per-frame strobe jitter *)
  -> support:support
  -> unit
