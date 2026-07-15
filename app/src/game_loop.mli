(** The terminal front end: raw-mode keyboard input driving {!Game}.

    One keypress, one {!Game.Action}, one repaint with {!Render.render}. Key
    bindings: [enter]/[space] starts from the start screen; while playing,
    [w] moves forward, [a]/[d] turn, [s] turns around and [q] gives up back
    to the start screen; [q] on the start screen (or [Ctrl-C] anywhere)
    leaves the game. Requires a real TTY and restores the terminal on the way
    out. *)

open! Core

val run : unit -> unit

(** Like {!run}, but paints with {!Render.render_map}: the whole maze is
    visible at once, fixed and unrotated, so you can watch it regenerate.
    Same keys, same rules — a debug front end, not the real game. *)
val run_map : unit -> unit
