open! Core
open Js_of_ocaml
open Bonsai_web
open Sandbox_engine
open Sandbox_app

let canvas_width = 720
let canvas_height = 560
let player_speed_cells_per_second = 5.3

(* Before the slip cutscene takes the screen, the trader is seen stepping the
   last cell onto the banana over the pre-slip maze; the banana is lifted and
   the cutscene begins the instant they land, so the step takes exactly as
   long as any other. A safety cap ends the beat even if the glide never
   reports arrival (e.g. a teleport snap). *)
let banana_approach_max_seconds = 0.5

(* Steps further apart than this are teleports (monster respawns, maze
   reshuffles): snap instead of gliding across the map. *)
let snap_distance_cells = 2.

module Input = struct
  type t =
    { flow : Flow.t
    ; cone_degrees : float
    ; view_cells : float
    ; monster_speed : float
    ; reveal_all : bool
    ; held : Direction.t list ref
    ; finish_cutscene : unit Effect.t
    ; start_run : unit Effect.t
    ; set_lobby_hud : zone:int -> can_enter:bool -> unit Effect.t
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

(* Everything the "walk onto the banana" beat needs, snapshotted the moment
   the slip cutscene begins: the engine has already reshuffled the maze by
   then, so we render this frozen copy of the maze the player was standing
   in, with the banana still in place until they reach it. *)
module Slip = struct
  type t =
    { maze : Maze.t
    ; target : Position.t
    ; facing : Direction.t
    ; cone_degrees : float
    ; view_cells : float
    }
end

module State = struct
  type t =
    { canvas : Dom_html.canvasElement Js.t
    ; ctx : Canvas2d.t
    ; mutable input : Input.t
    ; mutable raf : Dom_html.animation_frame_request_id option
    ; mutable last_frame_ms : float option
    ; mutable lobby : Lobby.t
    ; mutable lobby_hud_sent : (int * bool) option
    ; mutable entered_dunes : bool
    ; mutable cutscene_started_ms : float option
    ; mutable cutscene_finish_sent : bool
    ; mutable prev_screen : Flow.Screen.t
    ; mutable player : Glide.t option
    ; mutable monster : Glide.t option
    ; mutable last_playing_maze : Maze.t option
    ; mutable slip : Slip.t option
    ; scatter : Lobby_scene.scatter
    ; support : Cutscene_scene.support
    ; random_state : Random.State.t
    }

  let sexp_of_t (_ : t) = Sexp.Atom "<game-canvas-state>"
end

let dispatch effect = Vdom.Effect.Expert.handle_non_dom_event_exn effect

(* The torch pickup widens and lengthens the beam for a while. *)
let cone_and_view (state : State.t) game =
  let torch_lit = Game.torch_ticks_exn game > 0 in
  let cone_degrees =
    state.input.cone_degrees
    +. if torch_lit then Difficulty.torch_cone_bonus_degrees else 0.
  in
  let view_cells =
    state.input.view_cells
    +. if torch_lit then Difficulty.torch_view_bonus_cells else 0.
  in
  cone_degrees, view_cells
;;

(* The step onto the banana that precedes the slip: freeze the maze the
   player just left (the engine has already reshuffled [Flow.game]'s maze) so
   the approach animation has something to walk across. *)
let capture_slip (state : State.t) =
  match state.last_playing_maze with
  | None -> None
  | Some maze ->
    let game = Flow.game state.input.flow in
    let cone_degrees, view_cells = cone_and_view state game in
    Some
      { Slip.maze
      ; target = Game.player_exn game
      ; facing = Game.facing_exn game
      ; cone_degrees
      ; view_cells
      }
;;

let on_screen_change (state : State.t) (screen : Flow.Screen.t) =
  (match screen with
   | Lobby ->
     state.lobby <- Lobby.create ();
     state.lobby_hud_sent <- None;
     state.entered_dunes <- false;
     state.player <- None;
     state.monster <- None;
     state.slip <- None
   | Cutscene Banana_slip ->
     state.cutscene_started_ms <- None;
     state.cutscene_finish_sent <- false;
     state.slip <- capture_slip state
   | Cutscene (Jumpscare | Finding_o) ->
     state.cutscene_started_ms <- None;
     state.cutscene_finish_sent <- false;
     state.slip <- None
   | Playing | Won | Lost -> state.slip <- None);
  state.prev_screen <- screen
;;

let held_horizontal (state : State.t) =
  List.find !(state.input.held) ~f:(fun direction ->
    match (direction : Direction.t) with
    | East | West -> true
    | North | South -> false)
;;

let draw_lobby (state : State.t) ~now_ms ~dt =
  state.lobby <- Lobby.step state.lobby ~dt ~held:(held_horizontal state);
  let zone = Lobby.zone state.lobby in
  let can_enter = Lobby.can_enter state.lobby in
  (match state.lobby_hud_sent with
   | Some (sent_zone, sent_enter)
     when sent_zone = zone && Bool.equal sent_enter can_enter ->
     ()
   | Some (_ : int * bool) | None ->
     state.lobby_hud_sent <- Some (zone, can_enter);
     dispatch (state.input.set_lobby_hud ~zone ~can_enter));
  (* Walking north through the glowing gap starts the run. *)
  if can_enter && not state.entered_dunes
  then (
    match List.mem !(state.input.held) North ~equal:Direction.equal with
    | true ->
      state.entered_dunes <- true;
      dispatch state.input.start_run
    | false -> ());
  Lobby_scene.draw
    ~ctx:state.ctx
    ~now_ms
    ~lobby:state.lobby
    ~scatter:state.scatter
    ~can_enter
;;

let draw_playing (state : State.t) ~now_ms ~dt =
  let game = Flow.game state.input.flow in
  match Game.phase game with
  | Start_screen | Won | Lost ->
    (* Won/Lost keep the last frame under their DOM overlay. *)
    ()
  | Playing ->
    state.last_playing_maze <- Some (Game.maze_exn game);
    let player_position = Game.player_exn game in
    let monster_position = Monster.position (Game.monster_exn game) in
    let player =
      match state.player with
      | Some glide -> glide
      | None ->
        let glide = Glide.create player_position in
        state.player <- Some glide;
        glide
    in
    let monster =
      match state.monster with
      | Some glide -> glide
      | None ->
        let glide = Glide.create monster_position in
        state.monster <- Some glide;
        glide
    in
    Glide.retarget player player_position;
    Glide.retarget monster monster_position;
    Glide.advance player ~dt ~speed:player_speed_cells_per_second;
    Glide.advance monster ~dt ~speed:state.input.monster_speed;
    (match state.input.reveal_all with
     | true ->
       Maze_scene.draw_map
         ~ctx:state.ctx
         ~now_ms
         ~maze:(Game.maze_exn game)
         ~player:(Glide.entity player)
         ~facing:(Game.facing_exn game)
         ~monster:(Glide.entity monster)
     | false ->
       let cone_degrees, view_cells = cone_and_view state game in
       Maze_scene.draw
         ~ctx:state.ctx
         ~now_ms
         ~random_state:state.random_state
         ~maze:(Game.maze_exn game)
         ~player:(Glide.entity player)
         ~facing:(Game.facing_exn game)
         ~monster:(Glide.entity monster)
         ~cone_degrees
         ~view_cells)
;;

(* The trader takes the final step onto the banana over the frozen pre-slip
   maze; the banana vanishes the instant they land, right before the pratfall
   cutscene takes the whole screen. Returns whether they have landed. *)
let draw_slip_approach (state : State.t) ~now_ms ~dt ~(slip : Slip.t) =
  let player =
    match state.player with
    | Some glide -> glide
    | None ->
      let glide = Glide.create slip.target in
      state.player <- Some glide;
      glide
  in
  Glide.retarget player slip.target;
  Glide.advance player ~dt ~speed:player_speed_cells_per_second;
  let entity = Glide.entity player in
  let maze =
    if entity.moving
    then slip.maze
    else Maze.collect_banana slip.maze slip.target
  in
  let monster =
    match state.monster with
    | Some glide -> Glide.entity glide
    | None -> entity
  in
  Maze_scene.draw
    ~ctx:state.ctx
    ~now_ms
    ~random_state:state.random_state
    ~maze
    ~player:entity
    ~facing:slip.facing
    ~monster
    ~cone_degrees:slip.cone_degrees
    ~view_cells:slip.view_cells;
  not entity.moving
;;

let draw_cutscene (state : State.t) ~now_ms ~dt ~event =
  let started =
    match state.cutscene_started_ms with
    | Some started -> started
    | None ->
      state.cutscene_started_ms <- Some now_ms;
      now_ms
  in
  let elapsed = (now_ms -. started) /. 1000. in
  match state.slip with
  | Some slip ->
    (* [Banana_slip] leads with the trader stepping onto the banana at the
       normal walk speed. The moment they land (or the cap fires) the cutscene
       clock is restarted so the pratfall itself begins from zero. *)
    let arrived = draw_slip_approach state ~now_ms ~dt ~slip in
    if arrived || Float.( >= ) elapsed banana_approach_max_seconds
    then (
      state.slip <- None;
      state.cutscene_started_ms <- None)
  | None ->
    Cutscene_scene.draw
      ~ctx:state.ctx
      ~event
      ~t_seconds:elapsed
      ~now_ms
      ~random_state:state.random_state
      ~support:state.support;
    if Float.( >= ) elapsed (Cutscene.duration_seconds event)
       && not state.cutscene_finish_sent
    then (
      state.cutscene_finish_sent <- true;
      dispatch state.input.finish_cutscene)
;;

let draw_frame (state : State.t) ~now_ms =
  let dt =
    match state.last_frame_ms with
    | None -> 0.
    | Some last -> Float.min 0.05 ((now_ms -. last) /. 1000.)
  in
  state.last_frame_ms <- Some now_ms;
  let screen = Flow.screen state.input.flow in
  if not (Flow.Screen.equal screen state.prev_screen)
  then on_screen_change state screen;
  match screen with
  | Lobby -> draw_lobby state ~now_ms ~dt
  | Playing -> draw_playing state ~now_ms ~dt
  | Cutscene event -> draw_cutscene state ~now_ms ~dt ~event
  | Won | Lost -> draw_playing state ~now_ms ~dt
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
    let random_state = Random.State.default in
    let state =
      { State.canvas
      ; ctx = Canvas2d.context canvas
      ; input
      ; raf = None
      ; last_frame_ms = None
      ; lobby = Lobby.create ()
      ; lobby_hud_sent = None
      ; entered_dunes = false
      ; cutscene_started_ms = None
      ; cutscene_finish_sent = false
      ; prev_screen = Flow.screen input.flow
      ; player = None
      ; monster = None
      ; last_playing_maze = None
      ; slip = None
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
