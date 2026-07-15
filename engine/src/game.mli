(** The full game state machine.

    {v
      Start_screen --Start--> Playing --reach key-------> Won
           ^                     |    --caught by monster--> Lost
           |                     |
           +-------Quit----------+     Won/Lost: any action returns
                                       to the start screen.
    v}

    While [Playing], each {!Action.t} is one tick: the player moves or turns,
    then the monster takes a step. Stepping onto a banana slips the player —
    {!Maze.regenerate} rebuilds the walls around them with one banana fewer
    and the key where it always was — and the monster is respawned far away
    (it was part of the dream). Stepping onto the key wins; sharing a cell
    with the monster loses.

    Rendering lives elsewhere: {!Viewport} turns a game into what the player
    can see, and the [sandbox.app] library draws it. *)

open! Core

module Phase : sig
  type t =
    | Start_screen
    | Playing
    | Won
    | Lost
  [@@deriving sexp_of, compare, equal]
end

module Action : sig
  (** One keypress worth of intent. Movement is always relative to the
      direction the player faces. The monster moves on every action while
      playing, so turning in place is not free. *)
  type t =
    | Start
    | Quit
    | Move_forward
    | Turn_left
    | Turn_right
    | Turn_around
  [@@deriving sexp_of, compare, equal, enumerate]
end

type t [@@deriving sexp_of]

(** [create ~random_state ()] is a game sitting at the start screen. [rows]
    and [cols] must be odd and at least 5 (see {!Maze.generate}). Every run
    starts in the bottom-left corner facing north with [num_bananas] bananas
    on the map. *)
val create
  :  ?rows:int (** default 17 *)
  -> ?cols:int (** default 25 *)
  -> ?num_bananas:int (** bananas in the first maze; default 5 *)
  -> ?light_radius:int (** how far the player sees; default 4 *)
  -> ?monster:(module Monster.S) (** default {!Monster.Chaser} *)
  -> random_state:Random.State.t
  -> unit
  -> t

val handle_action : t -> Action.t -> t
val phase : t -> Phase.t
val light_radius : t -> int

(** The monster from the current or just-finished run, or [None] on the start
    screen. Lose screens like to name their killer. *)
val monster_name : t -> string option

(** Playing-phase accessors; they raise unless {!phase} is [Playing]. *)

val maze_exn : t -> Maze.t
val player_exn : t -> Position.t
val facing_exn : t -> Direction.t
val monster_exn : t -> Monster.packed
val bananas_remaining_exn : t -> int

module For_testing : sig
  (** Teleports the player mid-game (Playing phase only; raises on a wall).
      Tests use it to stage encounters with bananas, monsters and the key
      without depending on a particular maze layout. *)
  val with_player : t -> Position.t -> facing:Direction.t -> t
end
