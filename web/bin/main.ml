(** Camel O entry point.

    Build with [dune build web] and open [_build/default/web/bin/index.html]
    in a browser. *)

open! Core

let () =
  Bonsai_web.Start.start
    (Sandbox_web.App.component
       ~random_state:(Random.State.make_self_init ()))
;;
