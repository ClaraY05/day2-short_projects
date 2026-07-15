open! Core
open Sandbox_engine
open Sandbox_app

let create ~seed =
  Game.create ~random_state:(Random.State.make [| seed |]) ()
;;

let print game = print_endline (Render.render ~ansi:false game)

let%expect_test "the start screen" =
  print (create ~seed:0);
  [%expect
    {|
             S  L  I  P

          a banana horror maze

    Somewhere in the dark there is a key.
    Something in the dark is hunting you.
    Step on a banana and you slip, wake,
    and the walls will have moved.

      [enter] descend        [q] quit
    |}]
;;

let%expect_test "the playing screen: torchlit view, banana count, keys" =
  let game = Game.handle_action (create ~seed:0) Start in
  print game;
  [%expect
    {|
    bananas underfoot: 5

            .
          ##. . .
          ##. ##. .
          ##. ######
          ##^ . . ##.
          ##########




    [w] forward   [a]/[d] turn   [s] about-face   [q] give up
    |}]
;;

let%expect_test "the win screen" =
  let game = Game.handle_action (create ~seed:0) Start in
  let maze = Game.maze_exn game in
  let key = Maze.key maze in
  let stand, facing =
    List.find_map_exn Direction.all ~f:(fun direction ->
      let stand = Direction.step key direction in
      if Maze.is_floor maze stand && not (Maze.is_banana maze stand)
      then Some (stand, Direction.turn_around direction)
      else None)
  in
  let game = Game.For_testing.with_player game stand ~facing in
  print (Game.handle_action game Move_forward);
  [%expect
    {|
         THE KEY TURNS.

    You are out. The maze forgets you.

         [any key] start screen
    |}]
;;

let%expect_test "the lose screen names the monster" =
  let game = Game.handle_action (create ~seed:0) Start in
  let maze = Game.maze_exn game in
  let monster = Monster.position (Game.monster_exn game) in
  let stand, facing =
    List.find_map_exn Direction.all ~f:(fun direction ->
      let stand = Direction.step monster direction in
      if Maze.is_floor maze stand && not (Maze.is_banana maze stand)
      then Some (stand, Direction.turn_around direction)
      else None)
  in
  let game = Game.For_testing.with_player game stand ~facing in
  print (Game.handle_action game Move_forward);
  [%expect
    {|
      .-------------------------.
     /      __         __       \
    |      /  \       /  \       |
    |      \__/       \__/       |
    |                            |
    |    \/\/\/\/\/\/\/\/\/\/    |
     \                          /
      '------------------------'

      IT HAS YOU. (caught by the chaser)

      [any key] start screen
    |}]
;;
