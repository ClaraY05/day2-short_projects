open! Core
open Sandbox_engine
module C = Canvas2d

type entity =
  { row : float
  ; col : float
  ; moving : bool
  }

let cell_size = 40.
let wall_strip = 5.
let sense_range = 6.

(* Pixel position of a continuous cell coordinate. *)
let to_px cells = cells *. cell_size

let draw_cell ctx ~maze ~cell ~sx ~sy ~now_ms ~brightness =
  if Maze.is_wall maze cell
  then (
    (* Lit walls glow amber â the mockup's signature look; the darkness
       overlay below dims them with distance like everything else. *)
    C.set_fill ctx Palette.wall;
    C.fill_rect ctx ~x:sx ~y:sy ~w:cell_size ~h:cell_size;
    C.set_fill ctx "#a85a12";
    C.fill_rect
      ctx
      ~x:(sx +. wall_strip)
      ~y:(sy +. wall_strip)
      ~w:(cell_size -. (2. *. wall_strip))
      ~h:(cell_size -. (2. *. wall_strip));
    C.set_fill ctx Palette.wall_highlight;
    C.fill_rect ctx ~x:sx ~y:sy ~w:cell_size ~h:2.;
    C.fill_rect ctx ~x:sx ~y:sy ~w:2. ~h:cell_size)
  else (
    C.set_fill ctx Palette.floor_dark;
    C.fill_rect ctx ~x:sx ~y:sy ~w:cell_size ~h:cell_size;
    let center_x = sx +. (cell_size /. 2.) in
    let center_y = sy +. (cell_size /. 2.) in
    if Maze.is_dot maze cell then Sprites.dot ~ctx ~x:center_x ~y:center_y;
    if Maze.is_torch maze cell
    then Sprites.torch ~ctx ~x:center_x ~y:center_y;
    if Maze.is_banana maze cell
    then Sprites.banana ~ctx ~x:center_x ~y:center_y ~scale:1.;
    if Position.equal cell (Maze.key maze)
    then
      Sprites.camel
        ~ctx
        ~x:center_x
        ~y:center_y
        ~now_ms
        ~style:`In_maze
        ~scale:1.);
  (* Darkness on top of everything in the cell. *)
  C.set_fill ctx [%string "rgba(4,4,12,%{1. -. brightness#Float})"];
  C.fill_rect ctx ~x:sx ~y:sy ~w:cell_size ~h:cell_size
;;

let draw
  ~ctx
  ~now_ms
  ~random_state
  ~maze
  ~player
  ~facing
  ~monster
  ~cone_degrees
  ~view_cells
  =
  let w = C.width ctx in
  let h = C.height ctx in
  C.set_fill ctx Palette.void;
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h;
  let player_px = to_px player.col in
  let player_py = to_px player.row in
  let cam_x = player_px -. (w /. 2.) in
  let cam_y = player_py -. (h /. 2.) in
  let first_col = Int.max 0 (Int.of_float (cam_x /. cell_size) - 1) in
  let last_col =
    Int.min
      (Maze.cols maze - 1)
      (Int.of_float ((cam_x +. w) /. cell_size) + 1)
  in
  let first_row = Int.max 0 (Int.of_float (cam_y /. cell_size) - 1) in
  let last_row =
    Int.min
      (Maze.rows maze - 1)
      (Int.of_float ((cam_y +. h) /. cell_size) + 1)
  in
  let flicker =
    0.92
    +. (0.06 *. Float.sin (now_ms /. 90.))
    +. Random.State.float random_state 0.03
  in
  let brightness cell =
    Lighting.brightness
      ~maze
      ~player_row:player.row
      ~player_col:player.col
      ~facing
      ~cone_degrees
      ~view_cells
      ~cell
  in
  List.iter
    (List.range first_row (last_row + 1))
    ~f:(fun row ->
      List.iter
        (List.range first_col (last_col + 1))
        ~f:(fun col ->
          let cell = Position.create ~row ~col in
          let b = brightness cell in
          if Float.( > ) b 0.015
          then (
            let b = Float.min 1. (b *. flicker) in
            let sx =
              Float.round_nearest (to_px (Float.of_int col) -. cam_x)
            in
            let sy =
              Float.round_nearest (to_px (Float.of_int row) -. cam_y)
            in
            draw_cell ctx ~maze ~cell ~sx ~sy ~now_ms ~brightness:b)));
  (* The beast: visible in the beam, or looming through the red sense when it
     is a few steps away. *)
  let monster_cell =
    Position.create
      ~row:(Int.of_float (Float.round_down monster.row))
      ~col:(Int.of_float (Float.round_down monster.col))
  in
  let monster_brightness = brightness monster_cell in
  let cell_distance =
    Float.abs (monster.row -. player.row)
    +. Float.abs (monster.col -. player.col)
  in
  let sense = Float.max 0. (1. -. (cell_distance /. sense_range)) in
  if Float.( > ) monster_brightness 0.04 || Float.( > ) sense 0.55
  then (
    let mx = Float.round_nearest (to_px monster.col -. cam_x) in
    let my = Float.round_nearest (to_px monster.row -. cam_y) in
    let alpha =
      Float.min 1. (Float.max monster_brightness (sense *. 0.55) +. 0.15)
    in
    C.save ctx;
    C.set_alpha ctx alpha;
    Sprites.beast ~ctx ~x:mx ~y:my ~cell_size ~color:Palette.beast;
    C.restore ctx);
  (* The trader. *)
  let px = Float.round_nearest (to_px player.col -. cam_x) in
  let py = Float.round_nearest (to_px player.row -. cam_y) in
  Sprites.trader
    ~ctx
    ~x:px
    ~y:(py +. 13.)
    ~facing
    ~now_ms
    ~moving:player.moving
    ~scale:1.
    ();
  (* Red pulse when the beast is near. *)
  if Float.( > ) sense 0.
  then (
    let alpha =
      sense *. 0.5 *. (0.6 +. (0.4 *. Float.sin (now_ms /. 120.)))
    in
    C.radial_gradient
      ctx
      ~x:(w /. 2.)
      ~y:(h /. 2.)
      ~r0:(h *. 0.2)
      ~r1:(h *. 0.72)
      ~stops:
        [ 0., "rgba(255,0,40,0)"
        ; 1., [%string "rgba(255,0,40,%{alpha#Float})"]
        ];
    C.fill_rect ctx ~x:0. ~y:0. ~w ~h);
  (* Torchlight vignette. *)
  C.radial_gradient
    ctx
    ~x:(w /. 2.)
    ~y:(h /. 2.)
    ~r0:(h *. 0.24)
    ~r1:(h *. 0.78)
    ~stops:[ 0., "rgba(0,0,0,0)"; 1., "rgba(0,0,0,0.86)" ];
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h
;;
