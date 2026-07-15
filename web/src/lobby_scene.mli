(** The desert-camp lobby, painted: sunset sky, parallax stars and dunes, the
    camp tent and fire, the tipped banana truck with its spill, the glowing
    gap in the dunes, and the trader walking through it all.

    A straight port of the Camel O mockup's [drawLobby]/[drawEntrance]/
    [drawCamp]/[drawTruck]. The caller owns the {!Sandbox_app.Lobby} state
    and the pre-rolled random scatter ({!type-scatter}) so the sky does not
    reshuffle every frame. *)

open! Core
open Sandbox_app

(** Star positions and banana-spill placements, rolled once per app run. *)
type scatter

val scatter : random_state:Random.State.t -> scatter

val draw
  :  ctx:Canvas2d.t
  -> now_ms:float
  -> lobby:Lobby.t
  -> scatter:scatter
  -> can_enter:bool
  -> unit
