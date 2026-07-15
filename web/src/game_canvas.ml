open! Core
open Js_of_ocaml
open Bonsai_web
open Sandbox_engine
open Sandbox_app

let canvas_width = 720
let canvas_height = 560
let player_speed_cells_per_second = 5.3

(* Steps further apart than this are teleports (monster respawns, maze
   reshuffles): snap instead of gliding across the map. *)
let snap_distance_cells = 2.

module Command = struct
  type t =
    | Start_run
    | Quit
  [@@deriving sexp_of]
end

module View_model = struct
  type t =
    { screen : Flow.Screen.t
    ; score : int
    ; slips : int
    ; lobby_zone : int
    ; can_enter : bool
    }
  [@@deriving sexp_of, equal]

  let initial =
    { screen = Lobby
    ; score = 0
    ; slips = 0
    ; lobby_zone = 0
    ; can_enter = false
    }
  ;;
end

module Input = struct
  type t =
    { config : Difficulty.config
    ; random_state : Random.State.t
    ; held : Direction.t list ref
    ; commands : Command.t list ref
    ; set_view_model : View_model.t -> unit Effect.t
    }

  let sexp_of_t (_ : t) = Sexp.Atom "<game-canvas>"
end

(* A sprite gliding between the turn-based cells. Coordinates are cell
   centers, in cell units. *)
module Glide = struct
  type t =
    { mutable row : float
    ; mutable col : float
    ; mutable target : Position.t
    ; mutable moving : bool
    }

  let center (position : Position.t) =
    Float.of_int position.row +. 0.5, Float.of_int position.col +. 0.5
  ;;

  let snap t position =
    let row, col = center position in
    t.row <- row;
    t.col <- col;
    t.target <- position;
    t.moving <- false
  ;;

  let create position =
    let row, col = center position in
    { row; col; target = position; moving = false }
  ;;

  let is_moving t = t.moving

  let retarget t position =
    if not (Position.equal t.target position)
    then (
      let row, col = center position in
      if Float.( > )
           (Float.abs (row -. t.row) +. Float.abs (col -. t.col))
           snap_distance_cells
      then snap t position
      else (
        t.target <- position;
        t.moving <- true))
  ;;

  let advance t ~dt ~speed =
    let target_row, target_col = center t.target in
    let d_row = target_row -. t.row in
    let d_col = target_col -. t.col in
    let distance = Float.hypot d_row d_col in
    let step = speed *. dt in
    if Float.( <= ) distance step
    then (
      t.row <- target_row;
      t.col <- target_col;
      t.moving <- false)
    else (
      t.row <- t.row +. (d_row /. distance *. step);
      t.col <- t.col +. (d_col /. distance *. step);
      t.moving <- true)
  ;;

  let entity t : Maze_scene.entity =
    { row = t.row; col = t.col; moving = t.moving }
  ;;
end

module State = struct
  type t =
    { canvas : Dom_html.canvasElement Js.t
    ; ctx : Canvas2d.t
    ; mutable input : Input.t
    ; mutable flow : Flow.t (* the authoritative game *)
    ; mutable raf : Dom_html.animation_frame_request_id option
    ; mutable last_frame_ms : float option
    ; mutable lobby : Lobby.t
    ; mutable entered_dunes : bool
    ; mutable cutscene_started_ms : float option
    ; mutable cutscene_finish_applied : bool
    ; mutable prev_screen : Flow.Screen.t
    ; mutable player : Glide.t option
    ; mutable monster : Glide.t option
    ; (* Baselines for the item-pickup cue: a rise in either while playing is
         a dot or torch collected. Reset on each entry into [Playing] so a
         finished run's score and a post-slip maze never re-trigger. *)
      mutable last_score : int
    ; mutable last_torch_ticks : int
    ; mutable last_view_model : View_model.t option
    ; scatter : Lobby_scene.scatter
    ; support : Cutscene_scene.support
    ; random_state : Random.State.t (* for rendering jitter, not the game *)
    }

  let sexp_of_t (_ : t) = Sexp.Atom "<game-canvas-state>"
end

(* Feeds a Bonsai effect back to the runtime from the animation-frame loop;
   the effect is enqueued and applied on Bonsai's own next frame. *)
let dispatch effect = Vdom.Effect.Expert.handle_non_dom_event_exn effect

let apply_command flow (command : Command.t) =
  match command with
  | Start_run -> Flow.start_run flow
  | Quit -> Flow.quit flow
;;

let drain_commands (state : State.t) =
  match !(state.input.commands) with
  | [] -> ()
  | pending ->
    state.input.commands := [];
    (* [pending] is most-recent-first; apply in the order pressed. *)
    state.flow
    <- List.fold (List.rev pending) ~init:state.flow ~f:apply_command
;;

let held_horizontal (state : State.t) =
  List.find !(state.input.held) ~f:(fun direction ->
    match (direction : Direction.t) with
    | East | West -> true
    | North | South -> false)
;;

(* The most-recently-held direction that actually leads onto a floor cell, so
   holding a key walks continuously and never spends ticks bumping a wall. *)
let playing_move_direction (state : State.t) =
  let game = Flow.game state.flow in
  match Game.phase game with
  | Playing ->
    let player = Game.player_exn game in
    let maze = Game.maze_exn game in
    List.find !(state.input.held) ~f:(fun direction ->
      Maze.is_floor maze (Direction.step player direction))
  | Start_screen | Won | Lost -> None
;;

(* Lobby has its own bed; the dunes and every cutscene (and the end screens
   they lead into) share the gameplay bed. *)
let music_for_screen : Flow.Screen.t -> Audio.Music.t = function
  | Lobby -> Lobby
  | Playing | Cutscene _ | Won | Lost -> Gameplay
;;

let on_screen_change (state : State.t) (screen : Flow.Screen.t) =
  (match screen with
   | Lobby ->
     state.lobby <- Lobby.create ();
     state.entered_dunes <- false;
     state.player <- None;
     state.monster <- None
   | Playing ->
     (* Fresh glides at the new spawn (a new run, or waking after a slip). *)
     let game = Flow.game state.flow in
     state.player <- Some (Glide.create (Game.player_exn game));
     state.monster
     <- Some (Glide.create (Monster.position (Game.monster_exn game)));
     state.last_score <- Game.score game;
     state.last_torch_ticks <- Game.torch_ticks_exn game
   | Cutscene event ->
     state.cutscene_started_ms <- None;
     state.cutscene_finish_applied <- false;
     (match event with
      | Banana_slip -> Audio.play_effect Banana_slip
      | Jumpscare -> Audio.play_effect Game_over
      | Finding_o -> ())
   | Won | Lost -> ());
  state.prev_screen <- screen
;;

(* A dot (score) or torch (light ticks) collected this frame. Runs only while
   playing, where [torch_ticks_exn] is valid; the baselines are re-seeded on
   every entry into [Playing] so nothing here fires spuriously. *)
let detect_pickup (state : State.t) =
  let game = Flow.game state.flow in
  let score = Game.score game in
  let torch_ticks = Game.torch_ticks_exn game in
  if score > state.last_score || torch_ticks > state.last_torch_ticks
  then Audio.play_effect Item_pickup;
  state.last_score <- score;
  state.last_torch_ticks <- torch_ticks
;;

let advance_lobby (state : State.t) ~dt =
  state.lobby <- Lobby.step state.lobby ~dt ~held:(held_horizontal state);
  if Lobby.can_enter state.lobby
     && (not state.entered_dunes)
     && List.mem !(state.input.held) North ~equal:Direction.equal
  then (
    state.entered_dunes <- true;
    state.flow <- Flow.start_run state.flow)
;;

let advance_playing (state : State.t) ~dt =
  let game = Flow.game state.flow in
  match Game.phase game, state.player, state.monster with
  | Playing, Some player, Some monster ->
    Glide.retarget player (Game.player_exn game);
    Glide.retarget monster (Monster.position (Game.monster_exn game));
    Glide.advance player ~dt ~speed:player_speed_cells_per_second;
    Glide.advance
      monster
      ~dt
      ~speed:state.input.config.Difficulty.monster_cells_per_second;
    (* Continuous movement: the instant the glide settles, take the next held
       step so the trader flows through corridors without stopping. *)
    if not (Glide.is_moving player)
    then (
      match playing_move_direction state with
      | None -> ()
      | Some direction ->
        state.flow <- Flow.move state.flow direction;
        (match Game.phase (Flow.game state.flow) with
         | Playing ->
           let game = Flow.game state.flow in
           Glide.retarget player (Game.player_exn game);
           Glide.retarget monster (Monster.position (Game.monster_exn game))
         | Start_screen | Won | Lost -> ()))
  | (Playing | Start_screen | Won | Lost), _, _ -> ()
;;

let advance_cutscene (state : State.t) ~now_ms ~event =
  let started =
    match state.cutscene_started_ms with
    | Some started -> started
    | None ->
      state.cutscene_started_ms <- Some now_ms;
      now_ms
  in
  let elapsed = (now_ms -. started) /. 1000. in
  if Float.( >= ) elapsed (Cutscene.duration_seconds event)
     && not state.cutscene_finish_applied
  then (
    state.cutscene_finish_applied <- true;
    state.flow <- Flow.finish_cutscene state.flow)
;;

let current_view_model (state : State.t) : View_model.t =
  let game = Flow.game state.flow in
  { screen = Flow.screen state.flow
  ; score = Game.score game
  ; slips = Game.slips game
  ; lobby_zone = Lobby.zone state.lobby
  ; can_enter = Lobby.can_enter state.lobby
  }
;;

let push_view_model (state : State.t) =
  let view_model = current_view_model state in
  match state.last_view_model with
  | Some previous when View_model.equal previous view_model -> ()
  | Some _ | None ->
    state.last_view_model <- Some view_model;
    dispatch (state.input.set_view_model view_model)
;;

let render_lobby (state : State.t) ~now_ms =
  Lobby_scene.draw
    ~ctx:state.ctx
    ~now_ms
    ~lobby:state.lobby
    ~scatter:state.scatter
    ~can_enter:(Lobby.can_enter state.lobby)
;;

let render_playing (state : State.t) ~now_ms =
  let game = Flow.game state.flow in
  match Game.phase game, state.player, state.monster with
  | Playing, Some player, Some monster ->
    let torch_lit = Game.torch_ticks_exn game > 0 in
    let config = state.input.config in
    let cone_degrees =
      config.Difficulty.cone_degrees
      +. if torch_lit then Difficulty.torch_cone_bonus_degrees else 0.
    in
    let view_cells =
      config.view_cells
      +. if torch_lit then Difficulty.torch_view_bonus_cells else 0.
    in
    Maze_scene.draw
      ~ctx:state.ctx
      ~now_ms
      ~random_state:state.random_state
      ~maze:(Game.maze_exn game)
      ~player:(Glide.entity player)
      ~facing:(Game.facing_exn game)
      ~monster:(Glide.entity monster)
      ~cone_degrees
      ~view_cells
  | (Playing | Start_screen | Won | Lost), _, _ ->
    (* Won/Lost leave the last maze frame frozen under the vdom overlay. *)
    ()
;;

let render_cutscene (state : State.t) ~now_ms ~event =
  let started = Option.value state.cutscene_started_ms ~default:now_ms in
  let t_seconds = (now_ms -. started) /. 1000. in
  Cutscene_scene.draw
    ~ctx:state.ctx
    ~event
    ~t_seconds
    ~now_ms
    ~random_state:state.random_state
    ~support:state.support
;;

let draw_frame (state : State.t) ~now_ms =
  let dt =
    match state.last_frame_ms with
    | None -> 0.
    | Some last -> Float.min 0.05 ((now_ms -. last) /. 1000.)
  in
  state.last_frame_ms <- Some now_ms;
  (* 1. transitions the chrome asked for (buttons, Confirm). *)
  drain_commands state;
  (* 2. advance the live game for whatever screen we are on. *)
  (match Flow.screen state.flow with
   | Lobby -> advance_lobby state ~dt
   | Playing -> advance_playing state ~dt
   | Cutscene event -> advance_cutscene state ~now_ms ~event
   | Won | Lost -> ());
  (* 3. react to any screen the advance produced (spawns, resets). *)
  let screen = Flow.screen state.flow in
  if not (Flow.Screen.equal screen state.prev_screen)
  then on_screen_change state screen;
  (* 4. keep the right bed looping (idempotent; also starts the opening
     lobby music, which no transition announces) and sound any pickup. *)
  Audio.play_music (music_for_screen screen);
  (match screen with
   | Playing -> detect_pickup state
   | Lobby | Cutscene _ | Won | Lost -> ());
  (* 5. mirror to the Bonsai chrome, then draw. *)
  push_view_model state;
  match screen with
  | Lobby -> render_lobby state ~now_ms
  | Playing -> render_playing state ~now_ms
  | Cutscene event -> render_cutscene state ~now_ms ~event
  | Won | Lost -> render_playing state ~now_ms
;;

let rec schedule_frame (state : State.t) =
  let id =
    Dom_html.window##requestAnimationFrame
      (Js.wrap_callback (fun timestamp ->
         draw_frame state ~now_ms:(Js.float_of_number timestamp);
         schedule_frame state))
  in
  state.raf <- Some id
;;

module Widget = struct
  type dom = Dom_html.canvasElement

  module Input = Input
  module State = State

  let name = "game-canvas"

  let create (input : Input.t) =
    let canvas = Dom_html.createCanvas Dom_html.document in
    canvas##.width := canvas_width;
    canvas##.height := canvas_height;
    canvas##setAttribute
      (Js.string "style")
      (Js.string
         (String.concat
            ~sep:";"
            [ "display:block"
            ; "width:100%"
            ; "height:auto"
            ; "image-rendering:pixelated"
            ; "border-radius:6px"
            ; [%string "background:%{Palette.void}"]
            ]));
    (* Rendering jitter uses a throwaway generator so it never perturbs the
       game's own maze RNG (which lives inside the flow). *)
    let random_state = Random.State.default in
    let flow =
      Flow.create ~config:input.config ~random_state:input.random_state ()
    in
    let state =
      { State.canvas
      ; ctx = Canvas2d.context canvas
      ; input
      ; flow
      ; raf = None
      ; last_frame_ms = None
      ; lobby = Lobby.create ()
      ; entered_dunes = false
      ; cutscene_started_ms = None
      ; cutscene_finish_applied = false
      ; prev_screen = Flow.screen flow
      ; player = None
      ; monster = None
      ; last_score = 0
      ; last_torch_ticks = 0
      ; last_view_model = None
      ; scatter = Lobby_scene.scatter ~random_state
      ; support = Cutscene_scene.support ~random_state
      ; random_state
      }
    in
    schedule_frame state;
    state, canvas
  ;;

  let update ~prev_input:(_ : Input.t) ~input ~state ~element =
    state.State.input <- input;
    state, element
  ;;

  let destroy ~prev_input:(_ : Input.t) ~state ~element:(_ : dom Js.t) =
    Option.iter state.State.raf ~f:(fun id ->
      Dom_html.window##cancelAnimationFrame id)
  ;;

  let to_vdom_for_testing = `Sexp_of_input
end

let node = unstage (Vdom.Node.widget_of_module (module Widget))
