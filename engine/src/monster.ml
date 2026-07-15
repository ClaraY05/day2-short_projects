open! Core

module type S = Monster_intf.S

type packed = Packed : (module S with type t = 'a) * 'a -> packed

let sexp_of_packed (Packed ((module M), monster)) =
  [%message M.name ~_:(monster : M.t)]
;;

let create (module M : S) position = Packed ((module M), M.create position)
let name (Packed ((module M), _)) = M.name
let position (Packed ((module M), monster)) = M.position monster

let step (Packed ((module M), monster)) ~maze ~player ~random_state =
  Packed ((module M), M.step monster ~maze ~player ~random_state)
;;

module Chaser = struct
  type t =
    { position : Position.t
    ; resting : bool
    }
  [@@deriving sexp_of]

  let name = "chaser"
  let create position = { position; resting = false }
  let position t = t.position

  let step t ~maze ~player ~random_state:_ =
    if t.resting
    then { t with resting = false }
    else (
      let position =
        Maze.next_step_toward maze ~from:t.position ~goal:player
        |> Option.value ~default:t.position
      in
      { position; resting = true })
  ;;
end

module Wanderer = struct
  type t = Position.t [@@deriving sexp_of]

  let name = "wanderer"
  let create position = position
  let position t = t

  let step t ~maze ~player:_ ~random_state =
    Direction.all
    |> List.filter_map ~f:(fun direction ->
      let next = Direction.step t direction in
      Option.some_if (Maze.is_floor maze next) next)
    |> List.random_element ~random_state
    |> Option.value ~default:t
  ;;
end
