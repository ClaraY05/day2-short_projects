open! Core
open Sandbox_engine

let start = Position.create ~row:15 ~col:1

let generate ~random_state =
  Maze.generate ~random_state ~rows:17 ~cols:25 ~num_bananas:5 ~start
;;

let%expect_test "a generated maze, drawn" =
  let maze = generate ~random_state:(Random.State.make [| 0 |]) in
  print_endline (Maze.For_testing.to_ascii maze);
  [%expect
    {|
    #########################
    #..K..............#.....#
    ###.###.#.#####.#..##.###
    #.b.#...............#...#
    #.###.#..####.###...###.#
    #.#...#...#.b.#.....#...#
    #.#.#...#.#.b##.#####.###
    #.#.#...#.#.#.#.....#...#
    #.####....#.#.#####.###.#
    #b......#...#.#.........#
    #############...#####.#.#
    #.........#...#...#...#.#
    #...####..#.#.###.#.###.#
    #.#...#...#.#.....#...#.#
    #.###...#.#.#########.#.#
    #...#...#......b......#.#
    #########################
    |}]
;;

let%expect_test "generation invariants hold across many seeds" =
  List.iter (List.range 0 100) ~f:(fun seed ->
    let maze = generate ~random_state:(Random.State.make [| seed |]) in
    let check name condition =
      if not condition
      then print_s [%message "invariant failed" (seed : int) name]
    in
    check "start is floor" (Maze.is_floor maze start);
    check "key is floor" (Maze.is_floor maze (Maze.key maze));
    check "five bananas" (Maze.num_bananas maze = 5);
    check "no banana on the start" (not (Maze.is_banana maze start));
    check "no banana on the key" (not (Maze.is_banana maze (Maze.key maze)));
    check
      "winnable"
      (Maze.For_testing.banana_free_path_exists maze ~from:start));
  [%expect {| |}]
;;

let%expect_test "regeneration keeps the key, drops a banana, spares the \
                 player"
  =
  List.iter (List.range 0 100) ~f:(fun seed ->
    let random_state = Random.State.make [| seed |] in
    let maze = generate ~random_state in
    (* Slip in an arbitrary reachable spot, as if the player wandered there
       before stepping on a banana. *)
    let player =
      List.random_element_exn ~random_state (Maze.floor_cells maze)
    in
    let regenerated = Maze.regenerate maze ~random_state ~player in
    let check name condition =
      if not condition
      then print_s [%message "invariant failed" (seed : int) name]
    in
    check
      "same size"
      (Maze.rows regenerated = Maze.rows maze
       && Maze.cols regenerated = Maze.cols maze);
    check
      "key unchanged"
      (Position.equal (Maze.key regenerated) (Maze.key maze));
    check "one banana fewer" (Maze.num_bananas regenerated = 4);
    check "player cell is floor" (Maze.is_floor regenerated player);
    check
      "no banana under the player"
      (not (Maze.is_banana regenerated player));
    check
      "winnable from the player"
      (Maze.For_testing.banana_free_path_exists regenerated ~from:player));
  [%expect {| |}]
;;

let%expect_test "of_ascii round-trips and reads features" =
  let maze = Maze.For_testing.of_ascii {|#####
#K.b#
#.#.#
#...#
#####|} in
  print_endline (Maze.For_testing.to_ascii maze);
  [%expect {|
    #####
    #K.b#
    #.#.#
    #...#
    #####
    |}];
  print_s
    [%message
      ""
        ~key:(Maze.key maze : Position.t)
        ~bananas:(Set.to_list (Maze.bananas maze) : Position.t list)];
  [%expect {| ((key ((row 1) (col 1))) (bananas (((row 1) (col 3))))) |}]
;;

let%expect_test "dimensions must be odd and at least 5" =
  Expect_test_helpers_core.require_does_raise (fun () ->
    Maze.generate
      ~random_state:(Random.State.make [| 0 |])
      ~rows:16
      ~cols:25
      ~num_bananas:0
      ~start:(Position.create ~row:1 ~col:1));
  [%expect
    {|
    ("Maze dimensions must be odd and >= 5"
      (rows 16)
      (cols 25))
    |}]
;;
