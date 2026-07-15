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
    | Move_absolute of Direction.t
    | Turn_left
    | Turn_right
    | Turn_around
  [@@deriving sexp_of, compare, equal, enumerate]
end

let points_per_dot = 10
let torch_boost_ticks = 24

type play =
  { maze : Maze.t
  ; player : Position.t
  ; facing : Direction.t
  ; monster : Monster.packed
  ; score : int
  ; slips : int
  ; torch_ticks : int
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
  | Playing { maze; player; facing; monster; score; slips; torch_ticks } ->
    [%message
      "Playing"
        (player : Position.t)
        (facing : Direction.t)
        (monster : Monster.packed)
        ~bananas:(Maze.num_bananas maze : int)
        (score : int)
        (slips : int)
        (torch_ticks : int)
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
let torch_ticks_exn t = (play_exn t).torch_ticks

let score t =
  match t.state with
  | Start_screen -> 0
  | Playing play | Won play | Lost play -> play.score
;;

let slips t =
  match t.state with
  | Start_screen -> 0
  | Playing play | Won play | Lost play -> play.slips
;;

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
    state =
      Playing
        { maze
        ; player = start
        ; facing = North
        ; monster
        ; score = 0
        ; slips = 0
        ; torch_ticks = 0
        }
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
  { t with
    state =
      Playing
        { play with maze; player = onto; monster; slips = play.slips + 1 }
  }
;;

let collect_pickups play ~cell =
  let play =
    if Maze.is_dot play.maze cell
    then
      { play with
        maze = Maze.collect_dot play.maze cell
      ; score = play.score + points_per_dot
      }
    else play
  in
  if Maze.is_torch play.maze cell
  then
    { play with
      maze = Maze.collect_torch play.maze cell
    ; torch_ticks = torch_boost_ticks
    }
  else play
;;

(* Movement always turns the player toward [direction] first, so bumping a
   wall still swings the torch beam (and still costs the tick). *)
let move t play ~direction =
  let play = { play with facing = direction } in
  let destination = Direction.step play.player direction in
  if not (Maze.is_floor play.maze destination)
  then step_monster t play
  else if Position.equal destination (Maze.key play.maze)
  then { t with state = Won { play with player = destination } }
  else if Position.equal destination (Monster.position play.monster)
  then { t with state = Lost { play with player = destination } }
  else if Maze.is_banana play.maze destination
  then slip t play ~onto:destination
  else
    step_monster
      t
      (collect_pickups { play with player = destination } ~cell:destination)
;;

let tick_torch play =
  { play with torch_ticks = max 0 (play.torch_ticks - 1) }
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
  | ( Start_screen
    , ( Quit | Move_forward | Move_absolute _ | Turn_left | Turn_right
      | Turn_around ) ) ->
    t
  | ( (Won _ | Lost _)
    , ( Start | Quit | Move_forward | Move_absolute _ | Turn_left
      | Turn_right | Turn_around ) ) ->
    { t with state = Start_screen }
  | Playing _, Quit -> { t with state = Start_screen }
  | Playing _, Start -> t
  | Playing play, Move_forward ->
    let play = tick_torch play in
    move t play ~direction:play.facing
  | Playing play, Move_absolute direction ->
    move t (tick_torch play) ~direction
  | Playing play, Turn_left ->
    let play = tick_torch play in
    step_monster t { play with facing = Direction.turn_left play.facing }
  | Playing play, Turn_right ->
    let play = tick_torch play in
    step_monster t { play with facing = Direction.turn_right play.facing }
  | Playing play, Turn_around ->
    let play = tick_torch play in
    step_monster t { play with facing = Direction.turn_around play.facing }
;;
