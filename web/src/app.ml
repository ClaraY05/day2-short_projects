open! Core
open Js_of_ocaml
open Bonsai_web
open Bonsai.Let_syntax
open Sandbox_engine
open Sandbox_app

module Action = struct
  type t =
    | Start_run
    | Quit
    | Move of Direction.t
    | Finish_cutscene
  [@@deriving sexp_of]
end

let apply_action flow (action : Action.t) =
  match action with
  | Start_run -> Flow.start_run flow
  | Quit -> Flow.quit flow
  | Move direction -> Flow.move flow direction
  | Finish_cutscene -> Flow.finish_cutscene flow
;;

(* Held keys back the lobby's per-frame walking, so they live in a ref the
   canvas widget reads directly; most recently pressed first. *)
let press held direction =
  held
  := direction
     :: List.filter !held ~f:(fun d -> not (Direction.equal d direction))
;;

let release held direction =
  held := List.filter !held ~f:(fun d -> not (Direction.equal d direction))
;;

let key_of_event event =
  Js.Optdef.case
    event##.key
    (fun () -> None)
    (fun key -> Some (Js.to_string key))
;;

let on_keydown ~held ~inject ~screen ~can_enter event =
  match Option.bind (key_of_event event) ~f:Controls.intent_of_key with
  | None -> Vdom.Effect.Ignore
  | Some intent ->
    (* Arrows and Space would scroll the page. *)
    Dom.preventDefault event;
    (match intent with
     | Move direction ->
       let track = Effect.of_sync_fun (press held) direction in
       let act =
         match (screen : Flow.Screen.t), (direction : Direction.t) with
         | Playing, (_ : Direction.t) -> inject (Action.Move direction)
         | Lobby, North when can_enter ->
           (* Stepping through the gap in the dunes, straight off the keydown
              like the mockup. *)
           inject Action.Start_run
         | Lobby, (_ : Direction.t)
         | (Cutscene _ | Won | Lost), (_ : Direction.t) ->
           (* In the lobby the canvas walks from [held]; end screens and
              cutscenes ignore movement. *)
           Vdom.Effect.Ignore
       in
       Vdom.Effect.Many [ track; act ]
     | Confirm ->
       (match (screen : Flow.Screen.t) with
        | Won | Lost -> inject Action.Start_run
        | Lobby when can_enter -> inject Action.Start_run
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
  let flow, inject =
    Bonsai.state_machine
      ~sexp_of_model:[%sexp_of: Flow.t]
      ~sexp_of_action:[%sexp_of: Action.t]
      ~default_model:(Flow.create ~config ~random_state ())
      ~apply_action:(fun _context flow action -> apply_action flow action)
      graph
  in
  let lobby_hud, set_lobby_hud = Bonsai.state (0, false) graph in
  let%arr flow and inject and lobby_hud and set_lobby_hud in
  let screen = Flow.screen flow in
  let zone, can_enter = lobby_hud in
  let game = Flow.game flow in
  let score = Game.score game in
  let slips = Game.slips game in
  let quit _ = inject Action.Quit in
  let retry _ = inject Action.Start_run in
  let canvas =
    Game_canvas.node
      { flow
      ; cone_degrees = config.Difficulty.cone_degrees
      ; view_cells = config.view_cells
      ; monster_speed = config.monster_cells_per_second
      ; held
      ; finish_cutscene = inject Action.Finish_cutscene
      ; start_run = inject Action.Start_run
      ; set_lobby_hud =
          (fun ~zone ~can_enter -> set_lobby_hud (zone, can_enter))
      }
  in
  let keyboard =
    [ Vdom.Attr.Global_listeners.keydown
        ~phase:Bubbling
        ~f:(on_keydown ~held ~inject ~screen ~can_enter)
    ; Vdom.Attr.Global_listeners.keyup ~phase:Bubbling ~f:(on_keyup ~held)
    ]
  in
  let overlay =
    match (screen : Flow.Screen.t) with
    | Playing -> playing_hud ~score ~slips ~quit
    | Lobby -> lobby_caption ~zone
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
