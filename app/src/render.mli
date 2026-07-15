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

(** [render_map game] is like {!render} but the playing phase shows the whole
    maze at once — no light mask, no rotation (the player glyph becomes a
    [^ v < >] arrow for its facing) — via
    {!Sandbox_engine.Viewport.full_map}. It exists to watch the maze
    regenerate as bananas are stepped on; the start, win and lose screens are
    identical to {!render}. *)
val render_map : ?ansi:bool (** default [true] *) -> Game.t -> string
