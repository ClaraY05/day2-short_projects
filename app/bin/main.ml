(** Slip entry point.

    Run with: dune exec app/bin/main.exe *)

open! Core

let () = Sandbox_app.Game_loop.run ()
