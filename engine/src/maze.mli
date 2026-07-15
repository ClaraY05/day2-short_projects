(** Maze grid: walls, one key, slippery bananas, score dots and torches.

    A maze is a fixed-size grid of wall and floor cells with a border of
    walls, a single key cell, a set of banana cells, a couple of torch cells
    and a dot on every remaining floor cell. Generation guarantees, by
    construction:

    - every floor cell is reachable from every other floor cell;
    - the player's cell and the key cell are floor;
    - no banana sits on the player's cell or the key cell;
    - at least one wall-free path from the player to the key crosses no
      banana, so the game is always winnable.

    {!Game} owns the rules: when the player steps on a banana it calls
    {!regenerate}, which rebuilds the walls (same size, same key location,
    one fewer banana) around the player's current position. Between
    regenerations the map never changes.

    {[
      let maze =
        Maze.generate
          ~random_state
          ~rows:17
          ~cols:25
          ~num_bananas:5
          ~start:(Position.create ~row:15 ~col:1)
      in
      Maze.is_floor maze (Maze.key maze) = true
    ]} *)

open! Core

type t [@@deriving sexp_of]

(** [generate ~random_state ~rows ~cols ~num_bananas ~start] carves a fresh
    maze and picks a key location far from [start]. [rows] and [cols] must be
    odd and at least 5; [start] must be strictly inside the border. Raises on
    invalid dimensions. Places at most [num_bananas] bananas (fewer if the
    maze has too few safe floor cells). *)
val generate
  :  random_state:Random.State.t
  -> rows:int
  -> cols:int
  -> num_bananas:int
  -> start:Position.t
  -> t

(** [regenerate t ~random_state ~player] is a new maze of the same size with
    the key in the same place, fresh walls that avoid [player] and the key,
    and one banana fewer than [t] currently has. All the guarantees of
    {!generate} hold with [player] as the start. *)
val regenerate : t -> random_state:Random.State.t -> player:Position.t -> t

val rows : t -> int
val cols : t -> int
val key : t -> Position.t
val bananas : t -> Set.M(Position).t
val num_bananas : t -> int

(** Collectible score pellets: one on every floor cell that is not the start,
    the key, a banana or a torch. {!Game} removes them with {!collect_dot} as
    the player walks. *)
val dots : t -> Set.M(Position).t

val num_dots : t -> int

(** Torch pickups (two per maze) that {!Game} turns into a temporary light
    boost. *)
val torches : t -> Set.M(Position).t

val in_bounds : t -> Position.t -> bool

(** [is_wall t position] is true for wall cells and for out-of-bounds
    positions, so callers can probe blindly. *)
val is_wall : t -> Position.t -> bool

(** [is_floor t position] = in bounds and not a wall. *)
val is_floor : t -> Position.t -> bool

val is_banana : t -> Position.t -> bool
val is_dot : t -> Position.t -> bool
val is_torch : t -> Position.t -> bool

(** [collect_dot t position] is [t] without the dot at [position] (a no-op if
    there is none there); [collect_torch] likewise for torches. *)
val collect_dot : t -> Position.t -> t

val collect_torch : t -> Position.t -> t

(** All floor cells, in no particular order. Handy for spawning things; see
    {!Game}. *)
val floor_cells : t -> Position.t list

(** [distance t ~from ~goal] is the length in steps of a shortest
    wall-avoiding path (bananas are fine to cross), or [None] if unreachable. *)
val distance : t -> from:Position.t -> goal:Position.t -> int option

(** [next_step_toward t ~from ~goal] is the first move of such a shortest
    path. Chasing monsters use it; see {!Monster.Chaser}. [None] if [goal] is
    unreachable or already reached. *)
val next_step_toward
  :  t
  -> from:Position.t
  -> goal:Position.t
  -> Position.t option

module For_testing : sig
  (** [banana_free_path t ~from] is a shortest path from [from] to the key
      (inclusive of both) that crosses neither walls nor bananas. Its
      existence is the winnability invariant; tests also replay it move by
      move through {!Game}. *)
  val banana_free_path : t -> from:Position.t -> Position.t list option

  val banana_free_path_exists : t -> from:Position.t -> bool

  (** Renders the grid with ['#'] walls, ['.'] floor, ['K'] key, ['b']
      bananas and ['T'] torches, one row per line. Dots are not rendered:
      they sit on almost every floor cell and would drown the picture. *)
  val to_ascii : t -> string

  (** Parses the format produced by {!to_ascii}. Raises if rows are ragged or
      there is not exactly one ['K']. Every floor cell that is not the key, a
      banana or a torch gets a dot. *)
  val of_ascii : string -> t
end
