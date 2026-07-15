open! Core
open Sandbox_engine
open Sandbox_app

(* A tiny, monster-free arena keeps the transitions deterministic: the statue
   never catches anyone we do not walk into. *)
module Statue = struct
  type t = Position.t [@@deriving sexp_of]

  let name = "statue"
  let create position = position
  let position t = t
  let step t ~maze:_ ~player:_ ~random_state:_ = t
end

let config =
  { (Difficulty.config Easy) with
    rows = 9
  ; cols = 9
  ; num_bananas = 2
  ; monster = (module Statue : Monster.S)
  }
;;

let create ~seed =
  Flow.create ~config ~random_state:(Random.State.make [| seed |]) ()
;;

(* The map-view front end: same flow, only [cutscenes:false]. *)
let create_map_view ~seed =
  Flow.create
    ~config
    ~cutscenes:false
    ~random_state:(Random.State.make [| seed |])
    ()
;;

let print_screen flow = print_s [%sexp (Flow.screen flow : Flow.Screen.t)]

(* Teleports the player to a floor cell adjacent to [target], facing it, and
   takes the single step; see [stage_next_to] in the engine tests. *)
let step_onto flow target =
  let game = Flow.game flow in
  let maze = Game.maze_exn game in
  let stand, direction =
    List.find_map_exn Direction.all ~f:(fun direction ->
      let stand = Direction.step target direction in
      if Maze.is_floor maze stand
         && (not (Maze.is_banana maze stand))
         && (not (Position.equal stand (Maze.key maze)))
         && not
              (Position.equal
                 stand
                 (Monster.position (Game.monster_exn game)))
      then Some (stand, Direction.turn_around direction)
      else None)
  in
  let flow =
    Flow.For_testing.map_game flow ~f:(fun game ->
      Game.For_testing.with_player game stand ~facing:direction)
  in
  Flow.move flow direction
;;

let%expect_test "lobby -> playing -> quit -> lobby" =
  let flow = create ~seed:0 in
  print_screen flow;
  let flow = Flow.start_run flow in
  print_screen flow;
  print_s [%sexp (Game.phase (Flow.game flow) : Game.Phase.t)];
  let flow = Flow.quit flow in
  print_screen flow;
  print_s [%sexp (Game.phase (Flow.game flow) : Game.Phase.t)];
  [%expect
    {|
    Lobby
    Playing
    Playing
    Lobby
    Start_screen
    |}]
;;

let%expect_test "reaching camel O plays Finding_o, then the win screen" =
  let flow = Flow.start_run (create ~seed:1) in
  let flow = step_onto flow (Maze.key (Game.maze_exn (Flow.game flow))) in
  print_screen flow;
  let flow = Flow.finish_cutscene flow in
  print_screen flow;
  print_s [%sexp (Game.phase (Flow.game flow) : Game.Phase.t)];
  [%expect {|
    (Cutscene Finding_o)
    Won
    Won
    |}]
;;

let%expect_test "a banana slip plays its cutscene and resumes in the \
                 reshuffled maze"
  =
  let flow = Flow.start_run (create ~seed:2) in
  let banana =
    Set.choose_exn (Maze.bananas (Game.maze_exn (Flow.game flow)))
  in
  let flow = step_onto flow banana in
  print_screen flow;
  print_s
    [%message
      ""
        ~slips:(Game.slips (Flow.game flow) : int)
        ~woke_on_banana_cell:
          (Position.equal (Game.player_exn (Flow.game flow)) banana : bool)];
  let flow = Flow.finish_cutscene flow in
  print_screen flow;
  [%expect
    {|
    (Cutscene Banana_slip)
    ((slips 1) (woke_on_banana_cell true))
    Playing
    |}]
;;

let%expect_test "walking into the beast plays the jumpscare, then the lose \
                 screen; retry starts a fresh run"
  =
  let flow = Flow.start_run (create ~seed:3) in
  let flow =
    step_onto flow (Monster.position (Game.monster_exn (Flow.game flow)))
  in
  print_screen flow;
  let flow = Flow.finish_cutscene flow in
  print_screen flow;
  let flow = Flow.start_run flow in
  print_screen flow;
  print_s [%message "" ~fresh_score:(Game.score (Flow.game flow) : int)];
  [%expect
    {|
    (Cutscene Jumpscare)
    Lost
    Playing
    (fresh_score 0)
    |}]
;;

let%expect_test "map view: a banana slip skips the cutscene and resumes \
                 straight in the reshuffled maze"
  =
  let flow = Flow.start_run (create_map_view ~seed:2) in
  let banana =
    Set.choose_exn (Maze.bananas (Game.maze_exn (Flow.game flow)))
  in
  let flow = step_onto flow banana in
  print_screen flow;
  print_s
    [%message
      ""
        ~slips:(Game.slips (Flow.game flow) : int)
        ~woke_on_banana_cell:
          (Position.equal (Game.player_exn (Flow.game flow)) banana : bool)];
  [%expect
    {|
    Playing
    ((slips 1) (woke_on_banana_cell true))
    |}]
;;

let%expect_test "map view: winning and losing skip their cutscenes too" =
  let won = Flow.start_run (create_map_view ~seed:1) in
  let won = step_onto won (Maze.key (Game.maze_exn (Flow.game won))) in
  print_screen won;
  let lost = Flow.start_run (create_map_view ~seed:3) in
  let lost =
    step_onto lost (Monster.position (Game.monster_exn (Flow.game lost)))
  in
  print_screen lost;
  [%expect
    {|
    Won
    Lost
    |}]
;;

let%expect_test "moves and cutscene endings are ignored where they make no \
                 sense"
  =
  let flow = create ~seed:4 in
  print_screen (Flow.move flow North);
  print_screen (Flow.finish_cutscene flow);
  print_screen (Flow.start_run (Flow.start_run flow));
  [%expect {|
    Lobby
    Lobby
    Playing
    |}]
;;
