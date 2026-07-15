(** The engine for {e Slip}, a top-down horror maze game.

    Pure game logic, no I/O: {!Maze} generates grids that are always
    winnable, {!Game} runs the state machine one action at a time, {!Monster}
    holds the pluggable monster behaviors, and {!Lighting} computes how far
    the player's torch reaches on the static map. Rendering and input live in
    the web frontend. *)

(** Compass directions and turning. *)
module Direction = Direction

(** The state machine: start screen, playing, won, lost. *)
module Game = Game

(** Torch-beam brightness per cell, with line of sight. *)
module Lighting = Lighting

(** Grid generation with a guaranteed banana-free path to the key. *)
module Maze = Maze

(** Monster behaviors behind one interface; see {!Monster_intf.S}. *)
module Monster = Monster

(** The interface new monster types implement. *)
module Monster_intf = Monster_intf

(** Grid coordinates. *)
module Position = Position
