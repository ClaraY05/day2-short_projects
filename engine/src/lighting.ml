open! Core

(* Tuning mirrors the Camel O mockup: a faint ambient ring of radius 1.7
   cells that fades to 55% at its edge, and a beam whose strength is the
   product of distance falloff and how close to the cone's axis the cell sits
   (saturating at 2/3 of the way in from the edge). *)
let ambient_radius_cells = 1.7
let ambient_edge_fade = 0.45
let axis_saturation = 1.5
let ray_step_cells = 0.25

let facing_vector (facing : Direction.t) =
  (* x grows with col, y with row, so North points at negative y. *)
  match facing with
  | North -> 0., -1.
  | South -> 0., 1.
  | East -> 1., 0.
  | West -> -1., 0.
;;

let cell_of_point ~row ~col =
  Position.create
    ~row:(Int.of_float (Float.round_down row))
    ~col:(Int.of_float (Float.round_down col))
;;

let line_of_sight ~maze ~from_row ~from_col ~cell =
  let target_row = Float.of_int cell.Position.row +. 0.5 in
  let target_col = Float.of_int cell.Position.col +. 0.5 in
  let d_row = target_row -. from_row in
  let d_col = target_col -. from_col in
  let distance = Float.hypot d_row d_col in
  let steps =
    Int.max 1 (Int.of_float (Float.round_up (distance /. ray_step_cells)))
  in
  let rec walk i =
    if i > steps
    then true
    else (
      let fraction = Float.of_int i /. Float.of_int steps in
      let sample =
        cell_of_point
          ~row:(from_row +. (d_row *. fraction))
          ~col:(from_col +. (d_col *. fraction))
      in
      if Position.equal sample cell
      then true
      else if Maze.is_wall maze sample
      then false
      else walk (i + 1))
  in
  walk 0
;;

let brightness
  ~maze
  ~player_row
  ~player_col
  ~facing
  ~cone_degrees
  ~view_cells
  ~cell
  =
  let target_row = Float.of_int cell.Position.row +. 0.5 in
  let target_col = Float.of_int cell.Position.col +. 0.5 in
  let vx = target_col -. player_col in
  let vy = target_row -. player_row in
  let distance = Float.hypot vx vy in
  if Float.( < ) distance 1e-6
  then 1.
  else (
    let ambient =
      if Float.( < ) distance ambient_radius_cells
      then 1. -. (distance /. ambient_radius_cells *. ambient_edge_fade)
      else 0.
    in
    let fx, fy = facing_vector facing in
    let along_axis = ((vx *. fx) +. (vy *. fy)) /. distance in
    let cone_edge = Float.cos (cone_degrees *. Float.pi /. 180.) in
    let beam =
      if Float.( > ) along_axis cone_edge
         && Float.( < ) distance view_cells
         && line_of_sight
              ~maze
              ~from_row:player_row
              ~from_col:player_col
              ~cell
      then (
        let distance_falloff = 1. -. (distance /. view_cells) in
        let axis_closeness =
          (along_axis -. cone_edge) /. (1. -. cone_edge)
        in
        distance_falloff *. Float.min 1. (axis_closeness *. axis_saturation))
      else 0.
    in
    Float.min 1. (Float.max ambient beam))
;;
