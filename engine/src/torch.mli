(** A torch: a pickable light source that sits on a maze cell.

    A torch is an interactable object, like the key and bananas: it occupies
    a single {!Position.t} on the grid. Stepping onto its cell picks it up —
    the game moves it off the map and into the player's {!Inventory} — and a
    carried torch can be placed back down on a floor cell. This module models
    only the object and where it rests; the pickup and placement rules that
    tie it to the maze and inventory belong to {!Game}.

    {[
      let torch = Torch.create (Position.create ~row:2 ~col:5) in
      Torch.is_at torch (Position.create ~row:2 ~col:5) = true
    ]} *)

open! Core

type t [@@deriving sexp_of, compare, equal]

(** [create position] is a torch resting on [position]. *)
val create : Position.t -> t

(** [position t] is the cell [t] sits on. *)
val position : t -> Position.t

(** [is_at t position] is whether [t] rests on [position]. The game uses it
    to detect the player stepping onto the torch, the moment it is picked up. *)
val is_at : t -> Position.t -> bool
