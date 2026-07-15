(** The side-scrolling desert camp the trader walks before entering the
    dunes.

    A one-dimensional world, in the mockup's pixel units: the camp tent on
    the left, the tipped banana truck in the middle, the glowing gap in the
    dunes on the right. Walking right advances through four dialogue
    {!zone}s, each swapping the trader's line in the caption box; past the
    gap, {!can_enter} turns on and the W key starts the run.

    The web frontend owns the clock and calls {!step} every animation frame;
    everything here is pure.

    {[
      let lobby = Lobby.step (Lobby.create ()) ~dt:0.5 ~held:(Some East) in
      Float.( > ) (Lobby.x lobby) (Lobby.x (Lobby.create ()))
    ]} *)

open! Core
open Sandbox_engine

type t [@@deriving sexp_of]

(** The trader starts by the camp tent, facing the dunes. *)
val create : unit -> t

(** [step t ~dt ~held] advances [dt] seconds of walking. [held] is the
    horizontal direction currently held ([East]/[West]; anything else means
    standing still). Position is clamped to the world's edges. *)
val step : t -> dt:float -> held:Direction.t option -> t

(** World x-coordinate of the trader, for the camera and sprite. *)
val x : t -> float

(** Which way the trader faces (only ever [East] or [West]). *)
val facing : t -> Direction.t

(** Whether the trader walked during the last {!step} (drives the bob of the
    sprite). *)
val is_walking : t -> bool

(** Dialogue zone, [0] to [3], monotonically tied to how far right the trader
    has walked. *)
val zone : t -> int

(** The trader's line for the current {!zone}. [dialogue_for_zone] is the
    same table keyed by the zone alone, for callers (the web HUD) that track
    the zone without the whole lobby. *)
val dialogue : t -> string

val dialogue_for_zone : int -> string

(** The caption box's speaker tab. *)
val speaker : string

(** True once the trader reaches the gap in the dunes. *)
val can_enter : t -> bool

(** Layout landmarks for the painter, in world pixels. *)

val world_width : float
val camp_x : float
val truck_x : float
val entrance_x : float
