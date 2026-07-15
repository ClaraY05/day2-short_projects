open! Core
open Sandbox_engine

module Screen = struct
  type t =
    | Lobby
    | Playing
    | Cutscene of Cutscene.Event.t
    | Won
    | Lost
  [@@deriving sexp_of, compare, equal]
end

type t =
  { game : Game.t
  ; screen : Screen.t
  ; cutscenes : bool
  }

let sexp_of_t t =
  [%message
    ""
      ~screen:(t.screen : Screen.t)
      ~phase:(Game.phase t.game : Game.Phase.t)]
;;

let screen t = t.screen
let game t = t.game

let create ?config ?(cutscenes = true) ~random_state () =
  let config =
    Option.value config ~default:(Difficulty.config Difficulty.default)
  in
  let game =
    Game.create
      ~rows:config.Difficulty.rows
      ~cols:config.cols
      ~num_bananas:config.num_bananas
      ~light_radius:(Int.of_float config.view_cells)
      ~monster:config.monster
      ~random_state
      ()
  in
  { game; screen = Lobby; cutscenes }
;;

(* Drives the underlying game to [Start_screen] no matter where it is: end
   screens need one action to dismiss, and a playing game quits. *)
let rewind_game game =
  match Game.phase game with
  | Start_screen -> game
  | Playing | Won | Lost -> Game.handle_action game Quit
;;

let start_run t =
  match t.screen with
  | Playing | Cutscene _ -> t
  | Lobby | Won | Lost ->
    { t with
      game = Game.handle_action (rewind_game t.game) Start
    ; screen = Playing
    }
;;

let quit t = { t with game = rewind_game t.game; screen = Lobby }

let move t direction =
  match t.screen with
  | Lobby | Cutscene _ | Won | Lost -> t
  | Playing ->
    let slips_before = Game.slips t.game in
    let game = Game.handle_action t.game (Move_absolute direction) in
    let slipped = Game.slips game > slips_before in
    (* With cutscenes off (the map view) each beat resolves straight to its
       screen; the engine has already reshuffled the maze on a slip, so the
       player simply wakes in the new one. *)
    let screen : Screen.t =
      match Game.phase game with
      | Start_screen -> Lobby
      | Won -> if t.cutscenes then Cutscene Finding_o else Won
      | Lost -> if t.cutscenes then Cutscene Jumpscare else Lost
      | Playing ->
        if t.cutscenes && slipped then Cutscene Banana_slip else Playing
    in
    { t with game; screen }
;;

module For_testing = struct
  let map_game t ~f = { t with game = f t.game }
end

let finish_cutscene t =
  match t.screen with
  | Lobby | Playing | Won | Lost -> t
  | Cutscene Banana_slip -> { t with screen = Playing }
  | Cutscene Finding_o -> { t with screen = Won }
  | Cutscene Jumpscare -> { t with screen = Lost }
;;
