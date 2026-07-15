open! Core
open Bonsai_web_test
open Sandbox_web

(* Styles are long inline strings; hide them so the structure stays readable.
   The canvas widget prints as its input's sexp. *)
let create_handle () =
  Handle.create
    (Result_spec.vdom
       ~filter_printed_attributes:(fun ~key ~data:(_ : string) ->
         not (String.equal key "style"))
       Fn.id)
    (App.component ~random_state:(Random.State.make [| 0 |]))
;;

let%expect_test "the app opens on the lobby: chrome, canvas and caption box" =
  let handle = create_handle () in
  Handle.show handle;
  [%expect
    {|
    <div @on_keydown_global @on_keyup_global>
      <div>
        <div>
          <span> ◣ CAMEL O ◢ </span>
          <span> DESERT TRADER </span>
        </div>
        <div>
          <game-canvas-widget> <game-canvas> </game-canvas-widget>
          <div> </div>
          <div>
            <div>
              <span> TRADER </span>
            </div>
            <div>
              <div>
                Camp's gone quiet without you, O. You slipped your rope before sunrise and wandered off into the dark.
              </div>
              <div>  ◂ ▸ / A D  walk the camp  ·  ▲ W  enter the dunes at the gap  </div>
            </div>
          </div>
        </div>
        <div>  FOLLOW THE LANTERN · MIND THE BANANAS · FIND CAMEL O  </div>
      </div>
    </div>
    |}]
;;
