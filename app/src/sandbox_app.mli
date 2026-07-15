(** The terminal front end for {e Slip}.

    Everything here is I/O; the rules live in [sandbox.engine]. {!Render}
    turns a {!Sandbox_engine.Game} into a screenful of text and {!Game_loop}
    owns the keyboard and the terminal. *)

(** Timed full-screen animations (banana slips, jumpscares); frames not drawn
    yet. *)
module Cutscene = Cutscene

(** Raw-mode keyboard loop; the executable in [app/bin] just calls
    {!Game_loop.run}. *)
module Game_loop = Game_loop

(** One screen of text per game phase. *)
module Render = Render
