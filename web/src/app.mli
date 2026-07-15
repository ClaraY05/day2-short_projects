(** The whole Camel O page as one Bonsai component.

    Bonsai holds the truth: a {!Sandbox_app.Flow} in a state machine plus the
    lobby caption state, rendered as the mockup's chrome — header, glowing
    console frame, scanlines, HUD, caption box, end screens — with the
    {!Game_canvas} widget doing the pixel work inside. Global key listeners
    translate {!Sandbox_app.Controls} intents into state-machine actions; one
    keypress is one turn-based game tick.

    {[
      let () =
        Bonsai_web.Start.start
          (App.component ~random_state:(Random.State.make_self_init ()))
      ;;
    ]} *)

open! Core
open Bonsai_web
open Sandbox_app

val component
  :  ?difficulty:Difficulty.t (** default {!Difficulty.default} *)
  -> random_state:Random.State.t
  -> local_ Bonsai.graph
  -> Vdom.Node.t Bonsai.t
