(** The engine for {e Slip}, a top-down horror maze game.

    Pure game logic, no I/O: {!Maze} generates grids that are always
    winnable, {!Game} runs the state machine one action at a time, {!Monster}
    holds the pluggable monster behaviors, and {!Viewport} computes the
    rotated, torch-lit view the player sees. Rendering and input live in the
    [sandbox.app] library. *)

(** Compass directions and turning. *)
module Direction = Direction

(** The state machine: start screen, playing, won, lost. *)
module Game = Game

(** Grid generation with a guaranteed banana-free path to the key. *)
module Maze = Maze

(** Monster behaviors behind one interface; see {!Monster_intf.S}. *)
module Monster = Monster

(** The interface new monster types implement. *)
module Monster_intf = Monster_intf

(** Grid coordinates. *)
module Position = Position

(** The player's rotated, light-limited point of view. *)
module Viewport = Viewport
