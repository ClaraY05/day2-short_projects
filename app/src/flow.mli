(** The whole app's state machine: lobby, maze runs and the cutscenes between
    them.

    {v
      Lobby --start_run--> Playing --slip on banana--> Cutscene Banana_slip
        ^                    |  ^                            | (back to the
        |                    |  +----------------------------+  new maze)
        |                    +--reach camel O--> Cutscene Finding_o --> Won
        |                    +--caught--------> Cutscene Jumpscare --> Lost
        +------quit---------------(from anywhere)---+   Won/Lost: retry
                                                        via start_run
    v}

    {!Flow} wraps {!Sandbox_engine.Game} (which stays turn-based: one {!move}
    is one tick) and inserts the {!Cutscene.Event}s the design plays at each
    dramatic beat. The web frontend animates the cutscene and calls
    {!finish_cutscene} when its {!Cutscene.duration_seconds} is up;
    everything here is pure and instant, which is what the tests exercise. *)

open! Core
open Sandbox_engine

module Screen : sig
  type t =
    | Lobby
    | Playing
    | Cutscene of Cutscene.Event.t
    | Won
    | Lost
  [@@deriving sexp_of, compare, equal]
end

type t [@@deriving sexp_of]

(** [create ~random_state ()] sits in the lobby. [config] defaults to
    {!Difficulty.default}'s config. *)
val create
  :  ?config:Difficulty.config
  -> random_state:Random.State.t
  -> unit
  -> t

val screen : t -> Screen.t

(** The underlying game. On the [Lobby] screen it idles at
    {!Sandbox_engine.Game.Phase.Start_screen}; during
    [Cutscene (Banana_slip)] it already holds the reshuffled maze the player
    wakes into. *)
val game : t -> Game.t

(** Begins a run: from the lobby, or from an end screen (the design's PLAY
    AGAIN). A no-op while playing or mid-cutscene. *)
val start_run : t -> t

(** Back to the lobby, abandoning any run (the design's QUIT buttons). *)
val quit : t -> t

(** One turn-based tick: face [direction], step, let the beast move. Slips,
    wins and losses come back as the matching cutscene screen. A no-op off
    the [Playing] screen. *)
val move : t -> Direction.t -> t

(** What the current cutscene resolves into: the reshuffled maze for
    [Banana_slip], the end screens for [Finding_o]/[Jumpscare]. A no-op on
    other screens. *)
val finish_cutscene : t -> t

module For_testing : sig
  (** Rewrites the underlying game, e.g. with
      {!Sandbox_engine.Game.For_testing.with_player} to stage an encounter.
      The screen is untouched. *)
  val map_game : t -> f:(Game.t -> Game.t) -> t
end
