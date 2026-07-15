(** Camel O map-view entry point: the whole maze at once, fully lit, no
    cutscenes — for watching it reshuffle as the trader slips on bananas.
    Same page and controls as {!Sandbox_web.App}, just [~map_view:true].

    Build with [dune build web] and open
    [_build/default/web/bin/map_view.html] in a browser, or serve it with
    [dune exec web/serve/serve.exe] and visit [/map_view.html]. *)

open! Core

let () =
  Bonsai_web.Start.start
    (Sandbox_web.App.component
       ~map_view:true
       ~random_state:(Random.State.make_self_init ()))
;;
