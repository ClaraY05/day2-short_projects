open! Core
open Js_of_ocaml
open Bonsai_web
open Bonsai.Let_syntax
open Sandbox_engine
open Sandbox_app
module Command = Game_canvas.Command
module View_model = Game_canvas.View_model

(* Held keys back the widget's per-frame walking (lobby and in-game), so they
   live in a ref the canvas reads directly; most recently pressed first. *)
let press held direction =
  held
  := direction
     :: List.filter !held ~f:(fun d -> not (Direction.equal d direction))
;;

let release held direction =
  held := List.filter !held ~f:(fun d -> not (Direction.equal d direction))
;;

(* Screen transitions the chrome requests; the widget drains this queue each
   frame and applies them to its live game. *)
let push_command commands command = commands := command :: !commands

let key_of_event event =
  Js.Optdef.case
    event##.key
    (fun () -> None)
    (fun key -> Some (Js.to_string key))
;;

let on_keydown ~held ~commands ~screen ~can_enter event =
  match Option.bind (key_of_event event) ~f:Controls.intent_of_key with
  | None -> Vdom.Effect.Ignore
  | Some intent ->
    (* Arrows and Space would otherwise scroll the page. *)
    Dom.preventDefault event;
    (match intent with
     | Move direction ->
       (* Record the key; the widget's animation-frame loop reads [held] and
          drives all movement — lobby walking, entering the dunes at the gap,
          and continuous in-game stepping — with no Bonsai round-trip. As a
          convenience a tap of W right at the gap also enters immediately, so
          you need not hold it (the [entered_dunes] guard prevents a double
          start). *)
       let track = Effect.of_sync_fun (press held) direction in
       (match (screen : Flow.Screen.t), (direction : Direction.t) with
        | Lobby, North when can_enter ->
          Vdom.Effect.Many
            [ track
            ; Effect.of_sync_fun (push_command commands) Command.Start_run
            ]
        | (Lobby | Playing | Cutscene _ | Won | Lost), _ -> track)
     | Confirm ->
       (match (screen : Flow.Screen.t) with
        | Won | Lost ->
          Effect.of_sync_fun (push_command commands) Command.Start_run
        | Lobby when can_enter ->
          Effect.of_sync_fun (push_command commands) Command.Start_run
        | Lobby | Playing | Cutscene _ -> Vdom.Effect.Ignore))
;;

let on_keyup ~held event =
  match Option.bind (key_of_event event) ~f:Controls.intent_of_key with
  | Some (Move direction) -> Effect.of_sync_fun (release held) direction
  | Some Confirm | None -> Vdom.Effect.Ignore
;;

let playing_hud ~score ~slips ~quit =
  {%html|
    <div %{Styles.hud_bar}>
      <div %{Styles.hud_stats}>
        <span %{Styles.hud_goal}>◈ FIND CAMEL O</span>
        <span>SLIPS <span %{Styles.hud_slips_value}>%{slips#Int}</span></span>
        <span>PTS <span %{Styles.hud_score_value}>%{score#Int}</span></span>
      </div>
      <button %{Styles.hud_quit_button} on_click=%{quit}>QUIT ✕</button>
    </div>
  |}
;;

let lobby_caption ~zone =
  {%html|
    <div %{Styles.caption_area}>
      <div %{Styles.caption_tab}>
        <span %{Styles.caption_tab_text}>#{Lobby.speaker}</span>
      </div>
      <div %{Styles.caption_box}>
        <div %{Styles.caption_text}>#{Lobby.dialogue_for_zone zone}</div>
        <div %{Styles.caption_hint}>
          ◂ ▸ / A D  walk the camp  ·  ▲ W  enter the dunes at the gap
        </div>
      </div>
    </div>
  |}
;;

let won_overlay ~score ~slips ~retry ~quit =
  {%html|
    <div %{Styles.overlay_won}>
      <div %{Styles.won_title}>YOU FOUND CAMEL O</div>
      <div %{Styles.won_stats}>
        REUNITED AT LAST · SLIPS
        <span %{Styles.hud_slips_value}>%{slips#Int}</span> · SCORE
        <span %{Styles.hud_score_value}>%{score#Int}</span>
      </div>
      <div %{Styles.button_row}>
        <button %{Styles.primary_button ~fill:Palette.win} on_click=%{retry}>
          PLAY AGAIN
        </button>
        <button %{Styles.ghost_button} on_click=%{quit}>QUIT</button>
      </div>
    </div>
  |}
;;

let lost_overlay ~retry ~quit =
  {%html|
    <div %{Styles.overlay_lost}>
      <div %{Styles.lost_title}>MAULED</div>
      <div %{Styles.lost_stats}>THE WILD BEAST CAUGHT YOU IN THE DUNES</div>
      <div %{Styles.button_row}>
        <button %{Styles.primary_button ~fill:Palette.beast} on_click=%{retry}>
          TRY AGAIN
        </button>
        <button %{Styles.ghost_button} on_click=%{quit}>QUIT</button>
      </div>
    </div>
  |}
;;

let component ?(difficulty = Difficulty.default) ~random_state (local_ graph)
  =
  let config = Difficulty.config difficulty in
  let held : Direction.t list ref = ref [] in
  let commands : Command.t list ref = ref [] in
  let view_model, set_view_model =
    Bonsai.state
      ~sexp_of_model:[%sexp_of: View_model.t]
      ~equal:View_model.equal
      View_model.initial
      graph
  in
  let%arr view_model and set_view_model in
  let { View_model.screen; score; slips; lobby_zone; can_enter } =
    view_model
  in
  let quit _ = Effect.of_sync_fun (push_command commands) Command.Quit in
  let retry _ =
    Effect.of_sync_fun (push_command commands) Command.Start_run
  in
  let canvas =
    Game_canvas.node { config; random_state; held; commands; set_view_model }
  in
  let keyboard =
    [ Vdom.Attr.Global_listeners.keydown
        ~phase:Bubbling
        ~f:(on_keydown ~held ~commands ~screen ~can_enter)
    ; Vdom.Attr.Global_listeners.keyup ~phase:Bubbling ~f:(on_keyup ~held)
    ]
  in
  let overlay =
    match (screen : Flow.Screen.t) with
    | Playing -> playing_hud ~score ~slips ~quit
    | Lobby -> lobby_caption ~zone:lobby_zone
    | Won -> won_overlay ~score ~slips ~retry ~quit
    | Lost -> lost_overlay ~retry ~quit
    | Cutscene (_ : Cutscene.Event.t) -> Vdom.Node.none
  in
  {%html|
    <div %{Styles.page} *{keyboard}>
      <div %{Styles.column}>
        <div %{Styles.header_row}>
          <span %{Styles.header_title}>◣ CAMEL O ◢</span>
          <span>DESERT TRADER</span>
        </div>
        <div %{Styles.console}>
          %{canvas}
          <div %{Styles.scanlines}></div>
          %{overlay}
        </div>
        <div %{Styles.footer}>
          FOLLOW THE LANTERN · MIND THE BANANAS · FIND CAMEL O
        </div>
      </div>
    </div>
  |}
;;
