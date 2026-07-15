open! Core
open Sandbox_engine

type t =
  { x : float
  ; facing : Direction.t
  ; is_walking : bool
  }
[@@deriving sexp_of]

let world_width = 1900.
let camp_x = 300.
let truck_x = 840.
let entrance_x = 1740.
let walk_speed = 185.
let edge_margin = 120.
let enter_threshold = 1650.

(* The trader stops at the campfire the same way he stops at the gap: he may
   not walk onto it. [campfire_x] mirrors the fire the painter sets left of
   the tent; [left_limit] leaves his feet just clear of the flames. *)
let campfire_x = camp_x -. 74.
let left_limit = campfire_x +. 46.
let create () = { x = camp_x; facing = East; is_walking = false }

let step t ~dt ~held =
  let velocity =
    match (held : Direction.t option) with
    | Some East -> walk_speed
    | Some West -> -.walk_speed
    | Some North | Some South | None -> 0.
  in
  let facing =
    match (held : Direction.t option) with
    | Some ((East | West) as direction) -> direction
    | Some North | Some South | None -> t.facing
  in
  let x =
    Float.clamp_exn
      (t.x +. (velocity *. dt))
      ~min:left_limit
      ~max:(world_width -. edge_margin)
  in
  { x; facing; is_walking = Float.( <> ) velocity 0. }
;;

let x t = t.x
let facing t = t.facing
let is_walking t = t.is_walking

let zone t =
  if Float.( >= ) t.x 1560.
  then 3
  else if Float.( >= ) t.x 1150.
  then 2
  else if Float.( >= ) t.x 520.
  then 1
  else 0
;;

let speaker = "TRADER"

let dialogue_for_zone zone =
  match zone with
  | 0 ->
    "Camp's gone quiet without you, O. You slipped your rope before sunrise \
     and wandered off into the dark."
  | 1 ->
    "...and of course a banana truck tipped clean over the dunes. Peels \
     half-buried in the sand for miles."
  | 2 ->
    "One wrong step on those peels and the dunes seem to swallow you whole \
     \xe2\x80\x94 you wake somewhere else entirely."
  | _ ->
    "Your tracks lead straight into the deep dunes. Something out there is \
     howling. No more waiting \xe2\x80\x94 I'm coming for you, O."
;;

let dialogue t = dialogue_for_zone (zone t)
let can_enter t = Float.( > ) t.x enter_threshold
