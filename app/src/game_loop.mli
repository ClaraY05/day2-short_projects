(** The terminal front end: raw-mode keyboard input driving {!Game}.

    One keypress, one {!Game.Action}, one repaint with {!Render.render}. Key
    bindings: [enter]/[space] starts from the start screen; while playing,
    [w] moves forward, [a]/[d] turn, [s] turns around and [q] gives up back
    to the start screen; [q] on the start screen (or [Ctrl-C] anywhere)
    leaves the game. Requires a real TTY and restores the terminal on the way
    out. *)

open! Core

val run : unit -> unit
