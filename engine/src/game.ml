open! Core

module Phase = struct
  type t =
    | Start_screen
    | Playing
    | Won
    | Lost
  [@@deriving sexp_of, compare, equal]
end

module Action = struct
  type t =
    | Start
    | Quit
    | Move_forward
    | Turn_left
    | Turn_right
    | Turn_around
  [@@deriving sexp_of, compare, equal, enumerate]
end

type play =
  { maze : Maze.t
  ; player : Position.t
  ; facing : Direction.t
  ; monster : Monster.packed
  }

type state =
  | Start_screen
  | Playing of play
  | Won of play
  | Lost of play

type t =
  { state : state
  ; random_state : Random.State.t
  ; rows : int
  ; cols : int
  ; num_bananas : int
  ; light_radius : int
  ; monster_module : (module Monster.S)
  }

let phase t : Phase.t =
  match t.state with
  | Start_screen -> Start_screen
  | Playing _ -> Playing
  | Won _ -> Won
  | Lost _ -> Lost
;;

let monster_name t =
  match t.state with
  | Start_screen -> None
  | Playing play | Won play | Lost play -> Some (Monster.name play.monster)
;;

let sexp_of_t t =
  match t.state with
  | Start_screen | Won _ | Lost _ -> [%sexp (phase t : Phase.t)]
  | Playing { maze; player; facing; monster } ->
    [%message
      "Playing"
        (player : Position.t)
        (facing : Direction.t)
        (monster : Monster.packed)
        ~bananas:(Maze.num_bananas maze : int)
        (maze : Maze.t)]
;;

let light_radius t = t.light_radius

let play_exn t =
  match t.state with
  | Playing play -> play
  | Start_screen | Won _ | Lost _ ->
    raise_s
      [%message "Game: not in the Playing phase" ~phase:(phase t : Phase.t)]
;;

let maze_exn t = (play_exn t).maze
let player_exn t = (play_exn t).player
let facing_exn t = (play_exn t).facing
let monster_exn t = (play_exn t).monster
let bananas_remaining_exn t = Maze.num_bananas (maze_exn t)

let create
  ?(rows = 17)
  ?(cols = 25)
  ?(num_bananas = 5)
  ?(light_radius = 4)
  ?(monster = (module Monster.Chaser : Monster.S))
  ~random_state
  ()
  =
  { state = Start_screen
  ; random_state
  ; rows
  ; cols
  ; num_bananas
  ; light_radius
  ; monster_module = monster
  }
;;

(* The monster spawns on a floor cell far from the player (at least half the
   perimeter walk away when possible) and never on the key or a banana. *)
let spawn_monster t maze ~player =
  let far_enough = (t.rows + t.cols) / 2 in
  let candidates =
    Maze.floor_cells maze
    |> List.filter ~f:(fun cell ->
      (not (Position.equal cell player))
      && (not (Position.equal cell (Maze.key maze)))
      && not (Maze.is_banana maze cell))
    |> List.filter_map ~f:(fun cell ->
      Maze.distance maze ~from:player ~goal:cell
      |> Option.map ~f:(fun distance -> cell, distance))
  in
  let pool =
    match
      List.filter candidates ~f:(fun (_, distance) -> distance >= far_enough)
    with
    | _ :: _ as far -> far
    | [] ->
      (* Tiny maze: fall back to the farthest cells available. *)
      List.sort candidates ~compare:(fun (_, d1) (_, d2) ->
        Int.descending d1 d2)
      |> fun sorted -> List.take sorted 3
  in
  let position, _ =
    List.random_element_exn ~random_state:t.random_state pool
  in
  Monster.create t.monster_module position
;;

let start_playing t =
  let start = Position.create ~row:(t.rows - 2) ~col:1 in
  let maze =
    Maze.generate
      ~random_state:t.random_state
      ~rows:t.rows
      ~cols:t.cols
      ~num_bananas:t.num_bananas
      ~start
  in
  let monster = spawn_monster t maze ~player:start in
  { t with
    state = Playing { maze; player = start; facing = North; monster }
  }
;;

let step_monster t play =
  let monster =
    Monster.step
      play.monster
      ~maze:play.maze
      ~player:play.player
      ~random_state:t.random_state
  in
  let play = { play with monster } in
  if Position.equal (Monster.position monster) play.player
  then { t with state = Lost play }
  else { t with state = Playing play }
;;

let slip t play ~onto =
  let maze =
    Maze.regenerate play.maze ~random_state:t.random_state ~player:onto
  in
  let monster = spawn_monster t maze ~player:onto in
  { t with state = Playing { play with maze; player = onto; monster } }
;;

let move_forward t play =
  let destination = Direction.step play.player play.facing in
  if not (Maze.is_floor play.maze destination)
  then
    (* Bumping a wall wastes the tick; the monster still moves. *)
    step_monster t play
  else if Position.equal destination (Maze.key play.maze)
  then { t with state = Won { play with player = destination } }
  else if Position.equal destination (Monster.position play.monster)
  then { t with state = Lost { play with player = destination } }
  else if Maze.is_banana play.maze destination
  then slip t play ~onto:destination
  else step_monster t { play with player = destination }
;;

module For_testing = struct
  let with_player t position ~facing =
    let play = play_exn t in
    if not (Maze.is_floor play.maze position)
    then
      raise_s
        [%message
          "Game.For_testing.with_player: not a floor cell"
            (position : Position.t)];
    { t with state = Playing { play with player = position; facing } }
  ;;
end

let handle_action t (action : Action.t) =
  match t.state, action with
  | Start_screen, Start -> start_playing t
  | Start_screen, (Quit | Move_forward | Turn_left | Turn_right | Turn_around)
    ->
    t
  | ( (Won _ | Lost _)
    , (Start | Quit | Move_forward | Turn_left | Turn_right | Turn_around) )
    ->
    { t with state = Start_screen }
  | Playing _, Quit -> { t with state = Start_screen }
  | Playing _, Start -> t
  | Playing play, Move_forward -> move_forward t play
  | Playing play, Turn_left ->
    step_monster t { play with facing = Direction.turn_left play.facing }
  | Playing play, Turn_right ->
    step_monster t { play with facing = Direction.turn_right play.facing }
  | Playing play, Turn_around ->
    step_monster t { play with facing = Direction.turn_around play.facing }
;;
