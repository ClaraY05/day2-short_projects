open! Core
open Sandbox_engine

(* A monster that never moves. It is both a harmless prop for scripted tests
   and a demonstration that a new monster type is nothing more than an
   implementation of [Monster_intf.S]. *)
module Statue = struct
  type t = Position.t [@@deriving sexp_of]

  let name = "statue"
  let create position = position
  let position t = t
  let step t ~maze:_ ~player:_ ~random_state:_ = t
end

let create ~seed =
  Game.create
    ~random_state:(Random.State.make [| seed |])
    ~monster:(module Statue)
    ()
;;

let print_phase game = print_s [%sexp (Game.phase game : Game.Phase.t)]

let%expect_test "start screen -> playing -> quit -> start screen" =
  let game = create ~seed:0 in
  print_phase game;
  let game = Game.handle_action game Start in
  print_phase game;
  let game = Game.handle_action game Quit in
  print_phase game;
  [%expect {|
    Start_screen
    Playing
    Start_screen
    |}]
;;

let%expect_test "movement is relative to facing; turning costs a tick" =
  let game = Game.handle_action (create ~seed:0) Start in
  let before = Game.player_exn game in
  let game = Game.handle_action game Turn_right in
  print_s
    [%message
      ""
        ~facing:(Game.facing_exn game : Direction.t)
        ~moved:(not (Position.equal before (Game.player_exn game)) : bool)];
  [%expect {| ((facing East) (moved false)) |}]
;;

(* Replays a maze path through the game, one facing change and forward step
   at a time. *)
let walk game path =
  let direction_of_step ~from ~to_ =
    List.find_exn Direction.all ~f:(fun direction ->
      Position.equal (Direction.step from direction) to_)
  in
  let turns_toward ~facing ~target : Game.Action.t list =
    if Direction.equal facing target
    then []
    else if Direction.equal (Direction.turn_right facing) target
    then [ Turn_right ]
    else if Direction.equal (Direction.turn_left facing) target
    then [ Turn_left ]
    else [ Turn_around ]
  in
  List.fold path ~init:game ~f:(fun game next ->
    match Game.phase game with
    | Won | Lost | Start_screen -> game
    | Playing ->
      let target =
        direction_of_step ~from:(Game.player_exn game) ~to_:next
      in
      let turns = turns_toward ~facing:(Game.facing_exn game) ~target in
      List.fold (turns @ [ Move_forward ]) ~init:game ~f:Game.handle_action)
;;

let%expect_test "following the banana-free path wins the game" =
  let game = Game.handle_action (create ~seed:1) Start in
  let maze = Game.maze_exn game in
  let path =
    Maze.For_testing.banana_free_path maze ~from:(Game.player_exn game)
    |> Option.value_exn
  in
  (* The statue never moves, so unless it happens to be parked on the path
     (it is not, for this seed), the walk must end on the key. *)
  let statue = Monster.position (Game.monster_exn game) in
  print_s
    [%message
      "" ~statue_on_path:(List.mem path statue ~equal:Position.equal : bool)];
  let game = walk game (List.tl_exn path) in
  print_phase game;
  [%expect {|
    (statue_on_path false)
    Won
    |}]
;;

(* Finds a floor cell next to [target] and teleports the player there, facing
   [target]. *)
let stage_next_to game target =
  let maze = Game.maze_exn game in
  let stand, facing =
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
  Game.For_testing.with_player game stand ~facing
;;

let%expect_test "stepping onto the key wins; any key dismisses the end \
                 screen"
  =
  let game = Game.handle_action (create ~seed:2) Start in
  let game = stage_next_to game (Maze.key (Game.maze_exn game)) in
  let game = Game.handle_action game Move_forward in
  print_phase game;
  let game = Game.handle_action game Move_forward in
  print_phase game;
  [%expect {|
    Won
    Start_screen
    |}]
;;

let%expect_test "walking into the monster loses" =
  let game = Game.handle_action (create ~seed:3) Start in
  let game = stage_next_to game (Monster.position (Game.monster_exn game)) in
  let game = Game.handle_action game Move_forward in
  print_phase game;
  [%expect {| Lost |}]
;;

let%expect_test "slipping on a banana reshuffles the maze but not the key" =
  let game = Game.handle_action (create ~seed:4) Start in
  let maze = Game.maze_exn game in
  let key = Maze.key maze in
  let banana = Set.choose_exn (Maze.bananas maze) in
  let game = stage_next_to game banana in
  let game = Game.handle_action game Move_forward in
  let maze_after = Game.maze_exn game in
  print_s
    [%message
      ""
        ~phase:(Game.phase game : Game.Phase.t)
        ~woke_up_on_the_banana_cell:
          (Position.equal (Game.player_exn game) banana : bool)
        ~key_unchanged:(Position.equal (Maze.key maze_after) key : bool)
        ~bananas_remaining:(Game.bananas_remaining_exn game : int)
        ~walls_changed:
          (not
             (String.equal
                (Maze.For_testing.to_ascii maze)
                (Maze.For_testing.to_ascii maze_after))
           : bool)
        ~still_winnable:
          (Maze.For_testing.banana_free_path_exists
             maze_after
             ~from:(Game.player_exn game)
           : bool)];
  [%expect
    {|
    ((phase Playing) (woke_up_on_the_banana_cell true) (key_unchanged true)
     (bananas_remaining 4) (walls_changed true) (still_winnable true))
    |}]
;;

let%expect_test "the chaser shambles: one step toward the player, then a \
                 rest"
  =
  let maze = Maze.For_testing.of_ascii {|#######
#.....#
#K....#
#######|} in
  let player = Position.create ~row:1 ~col:1 in
  let random_state = Random.State.make [| 0 |] in
  let monster =
    Monster.create (module Monster.Chaser) (Position.create ~row:1 ~col:5)
  in
  let monster =
    List.fold (List.range 0 4) ~init:monster ~f:(fun monster _ ->
      let monster = Monster.step monster ~maze ~player ~random_state in
      print_s [%sexp (Monster.position monster : Position.t)];
      monster)
  in
  ignore (monster : Monster.packed);
  [%expect
    {|
    ((row 1) (col 4))
    ((row 1) (col 4))
    ((row 1) (col 3))
    ((row 1) (col 3))
    |}]
;;
