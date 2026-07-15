open! Core
open Sandbox_engine

(* One digit per cell, [round (brightness * 9)], so [0] is darkness and [9]
   full light. The player's cell is marked [@]. *)
let print_light maze ~player ~facing ~cone_degrees ~view_cells =
  let player_row = Float.of_int player.Position.row +. 0.5 in
  let player_col = Float.of_int player.Position.col +. 0.5 in
  List.range 0 (Maze.rows maze)
  |> List.iter ~f:(fun row ->
    List.range 0 (Maze.cols maze)
    |> List.map ~f:(fun col ->
      let cell = Position.create ~row ~col in
      if Position.equal cell player
      then '@'
      else (
        let brightness =
          Lighting.brightness
            ~maze
            ~player_row
            ~player_col
            ~facing
            ~cone_degrees
            ~view_cells
            ~cell
        in
        Char.of_int_exn
          (Char.to_int '0'
           + Int.of_float (Float.round_nearest (brightness *. 9.)))))
    |> String.of_char_list
    |> print_endline)
;;

let open_room =
  Maze.For_testing.of_ascii
    {|###########
#.........#
#.........#
#....K....#
#.........#
#.........#
###########|}
;;

let%expect_test "the beam is a cone: bright on the axis, fading to the \
                 sides and with distance"
  =
  let player = Position.create ~row:3 ~col:2 in
  print_light open_room ~player ~facing:East ~cone_degrees:40. ~view_cells:6.;
  [%expect
    {|
    00000000000
    00000221000
    06765431000
    07@86531000
    06765431000
    00000221000
    00000000000
    |}]
;;

let%expect_test "turning the beam moves the light, not the map" =
  let player = Position.create ~row:3 ~col:2 in
  print_light
    open_room
    ~player
    ~facing:North
    ~cone_degrees:40.
    ~view_cells:6.;
  [%expect
    {|
    04542000000
    05650000000
    06860000000
    07@70000000
    06760000000
    00000000000
    00000000000
    |}]
;;

let%expect_test "walls block the beam" =
  let maze =
    Maze.For_testing.of_ascii
      {|###########
#....#....#
#K...#....#
#.........#
###########|}
  in
  let player = Position.create ~row:1 ~col:2 in
  print_light maze ~player ~facing:East ~cone_degrees:40. ~view_cells:8.;
  [%expect
    {|
    06760000000
    07@87600000
    06765500000
    00000200000
    00000000000
    |}]
;;

let%expect_test "line of sight" =
  let maze = Maze.For_testing.of_ascii {|#####
#K#.#
#...#
#####|} in
  let sees ~cell =
    Lighting.line_of_sight
      ~maze
      ~from_row:1.5
      ~from_col:1.5
      ~cell:(Position.create ~row:(fst cell) ~col:(snd cell))
  in
  print_s
    [%message
      ""
        ~own_wall_face:(sees ~cell:(1, 2) : bool)
        ~around_the_corner:(sees ~cell:(1, 3) : bool)
        ~open_neighbor:(sees ~cell:(2, 2) : bool)];
  [%expect
    {| ((own_wall_face true) (around_the_corner false) (open_neighbor true)) |}]
;;
