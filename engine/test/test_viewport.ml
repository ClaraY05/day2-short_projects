open! Core
open Sandbox_engine

(* An asymmetric maze so rotation mistakes are visible. *)
let maze =
  Maze.For_testing.of_ascii
    {|#######
#K....#
#.###.#
#b..#.#
###.#.#
#.....#
#######|}
;;

let glyph (tile : Viewport.Tile.t option) =
  match tile with
  | None -> ' '
  | Some Player -> '@'
  | Some Wall -> '#'
  | Some Floor -> '.'
  | Some Banana -> 'b'
  | Some Key -> 'K'
  | Some Monster -> 'M'
;;

(* Rows are wrapped in [|] so the darkness at the edges stays visible in the
   expectation. *)
let print_view ~player ~facing ~monster ~radius =
  Viewport.view ~maze ~player ~facing ~monster ~radius
  |> Array.iter ~f:(fun row ->
    let cells =
      Array.to_list row |> List.map ~f:(fun t -> String.of_char (glyph t))
    in
    print_endline ("|" ^ String.concat cells ^ "|"))
;;

let center = Position.create ~row:3 ~col:2

let%expect_test "facing north: the view matches the map, player centered" =
  print_view ~player:center ~facing:North ~monster:None ~radius:2;
  [%expect
    {|
    |  .  |
    | .## |
    |#b@.#|
    | ##. |
    |  .  |
    |}]
;;

let%expect_test "turning rotates the world so 'ahead' is always up" =
  print_view ~player:center ~facing:East ~monster:None ~radius:2;
  [%expect
    {|
    |  #  |
    | #.. |
    |.#@#.|
    | .b# |
    |  #  |
    |}];
  print_view ~player:center ~facing:South ~monster:None ~radius:2;
  [%expect
    {|
    |  .  |
    | .## |
    |#.@b#|
    | ##. |
    |  .  |
    |}];
  print_view ~player:center ~facing:West ~monster:None ~radius:2;
  [%expect
    {|
    |  #  |
    | #b. |
    |.#@#.|
    | ..# |
    |  #  |
    |}]
;;

let%expect_test "the light is a circle: corners stay dark, the maze edge too"
  =
  print_view
    ~player:(Position.create ~row:5 ~col:3)
    ~facing:North
    ~monster:None
    ~radius:3;
  [%expect
    {|
    |   #   |
    | b..#. |
    | ##.#. |
    |#..@..#|
    | ##### |
    |       |
    |       |
    |}]
;;

let%expect_test "the monster shows up only inside the light" =
  let monster = Some (Position.create ~row:5 ~col:4) in
  print_view
    ~player:(Position.create ~row:5 ~col:3)
    ~facing:North
    ~monster
    ~radius:2;
  [%expect
    {|
    |  .  |
    | #.# |
    |..@M.|
    | ### |
    |     |
    |}];
  print_view
    ~player:(Position.create ~row:1 ~col:2)
    ~facing:North
    ~monster
    ~radius:2;
  [%expect
    {|
    |     |
    | ### |
    |#K@..|
    | .## |
    |  .  |
    |}]
;;

let print_full_map ~player ~monster =
  Viewport.full_map ~maze ~player ~monster
  |> Array.iter ~f:(fun row ->
    let cells =
      Array.to_list row |> List.map ~f:(fun t -> String.of_char (glyph t))
    in
    print_endline (String.concat cells))
;;

let%expect_test "the full map hides nothing and never rotates" =
  print_full_map
    ~player:center
    ~monster:(Some (Position.create ~row:5 ~col:5));
  [%expect
    {|
    #######
    #K....#
    #.###.#
    #b@.#.#
    ###.#.#
    #....M#
    #######
    |}]
;;
