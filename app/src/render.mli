(** Draws each {!Game.Phase} as a screenful of text.

    The playing screen is exactly the grid computed by
    {!Sandbox_engine.Viewport} — rotated so the player faces up, dark outside
    the torchlight — plus a banana counter and the key bindings. Pass
    [~ansi:false] to strip colors (and the lose screen's terminal bell),
    which the expect tests rely on. *)

open! Core
open Sandbox_engine

(** [render game] is the full screen for the game's current phase, ready to
    print after clearing the terminal. *)
val render : ?ansi:bool (** default [true] *) -> Game.t -> string
