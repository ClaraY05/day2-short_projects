open! Core

type t =
  { walls : bool array array
  ; rows : int
  ; cols : int
  ; key : Position.t
  ; bananas : Set.M(Position).t
  }

let rows t = t.rows
let cols t = t.cols
let key t = t.key
let bananas t = t.bananas
let num_bananas t = Set.length t.bananas

let in_bounds t { Position.row; col } =
  row >= 0 && row < t.rows && col >= 0 && col < t.cols
;;

let is_wall t ({ Position.row; col } as position) =
  (not (in_bounds t position)) || t.walls.(row).(col)
;;

let is_floor t position = in_bounds t position && not (is_wall t position)
let is_banana t position = Set.mem t.bananas position

let floor_cells t =
  List.concat_map (List.range 0 t.rows) ~f:(fun row ->
    List.filter_map (List.range 0 t.cols) ~f:(fun col ->
      let position = Position.create ~row ~col in
      Option.some_if (is_floor t position) position))
;;

(* Breadth-first search over floor cells, skipping [avoid]. Returns the
   predecessor of each reached cell, which is enough to recover both
   distances and paths. *)
let bfs t ~from ~avoid =
  let parents = Hashtbl.create (module Position) in
  if is_floor t from && not (Set.mem avoid from)
  then (
    Hashtbl.set parents ~key:from ~data:from;
    let queue = Queue.singleton from in
    let rec drain () =
      match Queue.dequeue queue with
      | None -> ()
      | Some position ->
        List.iter Direction.all ~f:(fun direction ->
          let next = Direction.step position direction in
          if is_floor t next
             && (not (Set.mem avoid next))
             && not (Hashtbl.mem parents next)
          then (
            Hashtbl.set parents ~key:next ~data:position;
            Queue.enqueue queue next));
        drain ()
    in
    drain ());
  parents
;;

let path t ~from ~goal ~avoid =
  let parents = bfs t ~from ~avoid in
  if not (Hashtbl.mem parents goal)
  then None
  else (
    let rec walk position acc =
      if Position.equal position from
      then position :: acc
      else walk (Hashtbl.find_exn parents position) (position :: acc)
    in
    Some (walk goal []))
;;

let no_avoid = Set.empty (module Position)

let distance t ~from ~goal =
  path t ~from ~goal ~avoid:no_avoid
  |> Option.map ~f:(fun p -> List.length p - 1)
;;

let next_step_toward t ~from ~goal =
  path t ~from ~goal ~avoid:no_avoid
  |> Option.bind ~f:(fun p -> List.nth p 1)
;;

(* Maze carving works on the "node lattice": cells whose row and column are
   both odd. Randomized depth-first search visits every node and knocks down
   the wall between consecutive nodes, so all nodes end up connected. *)

(* Note that [%] is the euclidean remainder, so this correctly rejects
   negative coordinates only because of the [> 0] checks. *)
let is_node ~rows ~cols { Position.row; col } =
  row % 2 = 1
  && col % 2 = 1
  && row > 0
  && col > 0
  && row < rows - 1
  && col < cols - 1
;;

let carve ~random_state ~rows ~cols =
  let walls = Array.make_matrix ~dimx:rows ~dimy:cols true in
  let clear { Position.row; col } = walls.(row).(col) <- false in
  let start = Position.create ~row:1 ~col:1 in
  let visited = Hash_set.create (module Position) in
  let rec visit node =
    Hash_set.add visited node;
    clear node;
    List.permute ~random_state Direction.all
    |> List.iter ~f:(fun direction ->
      let wall = Direction.step node direction in
      let next = Direction.step wall direction in
      if is_node ~rows ~cols next && not (Hash_set.mem visited next)
      then (
        clear wall;
        visit next))
  in
  visit start;
  walls
;;

(* Knocking out a few extra walls turns the perfect maze into one with loops,
   which makes banana placement more interesting and gives the player a
   chance to shake a chasing monster. *)
let braid ~random_state ~rows ~cols walls =
  let attempts = rows * cols / 8 in
  for _ = 1 to attempts do
    let row = 1 + Random.State.int random_state (rows - 2) in
    let col = 1 + Random.State.int random_state (cols - 2) in
    if walls.(row).(col)
    then (
      let position = Position.create ~row ~col in
      let open_neighbors =
        List.count Direction.all ~f:(fun direction ->
          let { Position.row; col } = Direction.step position direction in
          row >= 0
          && row < rows
          && col >= 0
          && col < cols
          && not walls.(row).(col))
      in
      if open_neighbors >= 2 then walls.(row).(col) <- false)
  done
;;

(* Every (odd, odd) interior cell is floor after carving, so any interior
   cell can be connected to the maze by clearing it and, if both its
   coordinates are even, one orthogonal neighbor as well. *)
let force_open ~random_state walls { Position.row; col } =
  walls.(row).(col) <- false;
  if row % 2 = 0 && col % 2 = 0
  then (
    let neighbor =
      List.random_element_exn
        ~random_state
        [ Position.create ~row:(row - 1) ~col
        ; Position.create ~row:(row + 1) ~col
        ]
    in
    walls.(neighbor.row).(neighbor.col) <- false)
;;

let validate ~rows ~cols ~start =
  if rows < 5 || cols < 5 || rows % 2 = 0 || cols % 2 = 0
  then
    raise_s
      [%message
        "Maze dimensions must be odd and >= 5" (rows : int) (cols : int)];
  let interior { Position.row; col } =
    row > 0 && row < rows - 1 && col > 0 && col < cols - 1
  in
  if not (interior start)
  then
    raise_s
      [%message
        "Maze start must be strictly inside the border" (start : Position.t)]
;;

(* Bananas may go anywhere except on one shortest start-to-key path, the
   start and the key, which is what keeps the maze winnable. *)
let place_bananas t ~random_state ~start ~num_bananas =
  match path t ~from:start ~goal:t.key ~avoid:no_avoid with
  | None ->
    raise_s
      [%message
        "BUG: freshly carved maze is not connected"
          (start : Position.t)
          ~key:(t.key : Position.t)]
  | Some protected_path ->
    let protected = Set.of_list (module Position) protected_path in
    let bananas =
      floor_cells t
      |> List.filter ~f:(fun cell -> not (Set.mem protected cell))
      |> List.permute ~random_state
      |> fun candidates -> List.take candidates num_bananas
    in
    { t with bananas = Set.of_list (module Position) bananas }
;;

let build ~random_state ~rows ~cols ~num_bananas ~start ~key =
  validate ~rows ~cols ~start;
  let walls = carve ~random_state ~rows ~cols in
  braid ~random_state ~rows ~cols walls;
  force_open ~random_state walls start;
  Option.iter key ~f:(force_open ~random_state walls);
  let t =
    { walls
    ; rows
    ; cols
    ; key = Option.value key ~default:start
    ; bananas = no_avoid
    }
  in
  let t =
    match key with
    | Some key -> { t with key }
    | None ->
      (* Pick the key at random among the third of floor cells farthest from
         the start, so there is always a real trek to it. *)
      let by_distance =
        floor_cells t
        |> List.filter_map ~f:(fun cell ->
          distance t ~from:start ~goal:cell
          |> Option.map ~f:(fun distance -> cell, distance))
        |> List.sort ~compare:(fun (_, d1) (_, d2) -> Int.descending d1 d2)
      in
      let farthest_third =
        List.take by_distance (1 + (List.length by_distance / 3))
      in
      let key, _ = List.random_element_exn ~random_state farthest_third in
      { t with key }
  in
  place_bananas t ~random_state ~start ~num_bananas
;;

let generate ~random_state ~rows ~cols ~num_bananas ~start =
  build ~random_state ~rows ~cols ~num_bananas ~start ~key:None
;;

let regenerate t ~random_state ~player =
  build
    ~random_state
    ~rows:t.rows
    ~cols:t.cols
    ~num_bananas:(max 0 (num_bananas t - 1))
    ~start:player
    ~key:(Some t.key)
;;

let to_ascii t =
  List.range 0 t.rows
  |> List.map ~f:(fun row ->
    List.range 0 t.cols
    |> List.map ~f:(fun col ->
      let position = Position.create ~row ~col in
      if is_wall t position
      then '#'
      else if Position.equal position t.key
      then 'K'
      else if is_banana t position
      then 'b'
      else '.')
    |> String.of_char_list)
  |> String.concat ~sep:"\n"
;;

let sexp_of_t t = [%sexp (String.split_lines (to_ascii t) : string list)]

module For_testing = struct
  let banana_free_path t ~from = path t ~from ~goal:t.key ~avoid:t.bananas

  let banana_free_path_exists t ~from =
    Option.is_some (banana_free_path t ~from)
  ;;

  let to_ascii = to_ascii

  let of_ascii ascii =
    let lines = String.split_lines ascii |> List.map ~f:String.strip in
    let lines =
      List.filter lines ~f:(fun line -> not (String.is_empty line))
    in
    let rows = List.length lines in
    let cols =
      match lines with
      | [] -> raise_s [%message "Maze.For_testing.of_ascii: empty grid"]
      | first :: rest ->
        List.iter rest ~f:(fun line ->
          if String.length line <> String.length first
          then
            raise_s
              [%message
                "Maze.For_testing.of_ascii: ragged rows" (line : string)]);
        String.length first
    in
    let walls = Array.make_matrix ~dimx:rows ~dimy:cols true in
    let keys = ref [] in
    let bananas = ref [] in
    List.iteri lines ~f:(fun row line ->
      String.iteri line ~f:(fun col char ->
        let position = Position.create ~row ~col in
        match char with
        | '#' -> ()
        | '.' -> walls.(row).(col) <- false
        | 'K' ->
          walls.(row).(col) <- false;
          keys := position :: !keys
        | 'b' ->
          walls.(row).(col) <- false;
          bananas := position :: !bananas
        | char ->
          raise_s
            [%message
              "Maze.For_testing.of_ascii: unknown cell" (char : char)]));
    match !keys with
    | [ key ] ->
      { walls
      ; rows
      ; cols
      ; key
      ; bananas = Set.of_list (module Position) !bananas
      }
    | keys ->
      raise_s
        [%message
          "Maze.For_testing.of_ascii: expected exactly one key"
            (keys : Position.t list)]
  ;;
end
