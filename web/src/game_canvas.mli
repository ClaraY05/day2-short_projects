(** The 720x560 game canvas as a Bonsai-compatible vdom widget that owns the
    live game.

    The widget holds the authoritative {!Sandbox_app.Flow} and runs the whole
    game in a [requestAnimationFrame] loop: it walks the lobby and drives
    in-game movement directly from the shared [held] ref (so a keypress moves
    the trader the same frame, with no Bonsai round-trip), times the
    cutscenes, and applies the screen-transition {!Command}s the chrome
    queues. Whenever the slice of state the chrome needs changes it pushes a
    fresh {!View_model} back to Bonsai; Bonsai only renders the HUD, caption
    and end screens from that mirror.

    This split — imperative game loop here, declarative chrome in {!App} — is
    what keeps input latency to a single animation frame. *)

open! Core
open Bonsai_web
open Sandbox_engine
open Sandbox_app

module Command : sig
  (** A one-shot screen transition the chrome asks for: the QUIT buttons, the
      PLAY AGAIN / TRY AGAIN buttons, and the Confirm key. The widget drains
      these each frame and applies them to its live {!Sandbox_app.Flow}. *)
  type t =
    | Start_run
    | Quit
  [@@deriving sexp_of]
end

module View_model : sig
  (** The slice of game state the Bonsai chrome renders: which screen shows,
      the HUD counters, the lobby caption's dialogue zone and dune gate, and
      the difficulty selected in the lobby book. The widget pushes a fresh
      one whenever it changes. *)
  type t =
    { screen : Flow.Screen.t
    ; score : int
    ; slips : int
    ; lobby_zone : int
    ; can_enter : bool
    ; difficulty : Difficulty.t
    }
  [@@deriving sexp_of, equal]

  (** What the chrome shows before the widget's first frame: the lobby, at
      the opening dialogue, dunes still locked. *)
  val initial : t
end

module Input : sig
  (** [held], [commands] and [difficulty] are refs shared with {!App}: its
      key handlers and buttons write them, the widget reads and drains them
      each frame — the low-latency channel that bypasses Bonsai
      stabilization. The lobby's number keys set [difficulty], and the widget
      reads it whenever a run starts. [random_state] seeds the game;
      [set_view_model] pushes the mirror. *)
  type t =
    { difficulty : Difficulty.t ref
    ; random_state : Random.State.t
    ; reveal_all : bool
    (** [true] for the map-view front end: run with cutscenes off and paint
        the whole maze fully lit with {!Maze_scene.draw_map} instead of the
        torch beam, so the reshuffle after a slip is watched end to end. *)
    ; held : Direction.t list ref
    ; commands : Command.t list ref
    ; set_view_model : View_model.t -> unit Effect.t
    }
end

(** [node input] is the canvas. Give it a stable place in the vdom and feed
    it new inputs as the mirror state changes. *)
val node : Input.t -> Vdom.Node.t
