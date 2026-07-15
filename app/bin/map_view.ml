(** Slip map-view entry point: the whole maze at once, fixed and unrotated,
    nothing hidden — for watching the maze regenerate. Same game, same keys.

    Run with: dune exec app/bin/map_view.exe *)

open! Core

let () = Sandbox_app.Game_loop.run_map ()
