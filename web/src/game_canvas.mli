(** The 720x560 game canvas as a Bonsai-compatible vdom widget.

    Bonsai owns the truth (a {!Sandbox_app.Flow} in a state machine); this
    widget owns the clock. A [requestAnimationFrame] loop repaints every
    frame: gliding the turn-based cell steps ({!Maze_scene.entity}), walking
    the lobby from the held keys, and timing the cutscenes. When something it
    observes should change the app state — a cutscene running its course, the
    trader stepping through the gap in the dunes, the dialogue zone changing
    — it hands back the effect given in {!Input.t}; it never mutates the flow
    itself. *)

open! Core
open Bonsai_web
open Sandbox_engine
open Sandbox_app

module Input : sig
  type t =
    { flow : Flow.t
    ; cone_degrees : float (** beam half-angle, before any torch boost *)
    ; view_cells : float (** beam reach, before any torch boost *)
    ; monster_speed : float (** beast glide speed, cells per second *)
    ; reveal_all : bool
    (** [true] for the map view: paint the whole maze fully lit with
        {!Maze_scene.draw_map} instead of the torch beam *)
    ; held : Direction.t list ref
    (** keys currently held, most recent first; shared with {!App}'s keyboard
        listeners *)
    ; finish_cutscene : unit Effect.t
    ; start_run : unit Effect.t (** dispatched at the dunes gap *)
    ; set_lobby_hud : zone:int -> can_enter:bool -> unit Effect.t
    }
end

(** [node input] is the canvas. Give the widget a stable place in the vdom
    and feed it new inputs as state changes. *)
val node : Input.t -> Vdom.Node.t
