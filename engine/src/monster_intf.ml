(** The interface every monster type implements.

    A monster is some private state (at minimum its position) plus a [step]
    function that advances it one game tick. {!Game} advances the monster
    once per player action, so slow monsters are implemented by resting on
    some ticks, not by moving fractionally.

    To add a new monster type, implement {!module-type:S} and hand the module
    to {!Game.create}; see {!module-Monster.Chaser} for an example. *)

open! Core

module type S = sig
  type t [@@deriving sexp_of]

  (** Shown on the lose screen: "caught by the chaser". *)
  val name : string

  (** [create position] spawns the monster at [position], which {!Game}
      guarantees is a floor cell away from the player. *)
  val create : Position.t -> t

  val position : t -> Position.t

  (** [step t ~maze ~player ~random_state] is the monster one tick later.
      Implementations must stay on floor cells; staying put is always
      allowed. Catching the player is simply returning a monster whose
      {!position} equals [player] — {!Game} turns that into the lose state. *)
  val step
    :  t
    -> maze:Maze.t
    -> player:Position.t
    -> random_state:Random.State.t
    -> t
end

module type Monster = sig
  module type S = S

  (** A monster packed together with its behavior, so mazes can host any
      monster type (and, later, several different ones) uniformly. *)
  type packed = Packed : (module S with type t = 'a) * 'a -> packed

  val sexp_of_packed : packed -> Sexp.t

  (** [create (module M) position] spawns an [M] and packs it. *)
  val create : (module S) -> Position.t -> packed

  val name : packed -> string
  val position : packed -> Position.t

  val step
    :  packed
    -> maze:Maze.t
    -> player:Position.t
    -> random_state:Random.State.t
    -> packed

  (** Shambles along a shortest path toward the player, resting every other
      tick so a decisive player can outrun it. Waits if no path exists. The
      easy-difficulty beast. *)
  module Chaser : S

  (** Like {!Chaser} but rests only every third tick, so it gains ground
      whenever the player hesitates. The normal-difficulty beast. *)
  module Prowler : S

  (** Like {!Chaser} but rests only every ninth tick: barely slower than the
      player. The nightmare-difficulty beast. *)
  module Sprinter : S

  (** Drifts to a random neighboring floor cell each tick. Harmless-ish;
      mostly a second example of implementing {!module-type:S}. *)
  module Wanderer : S
end
