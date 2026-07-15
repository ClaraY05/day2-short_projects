(** A torch: a pickable light source that sits on a maze cell.

    A torch is an interactable object, like the key and bananas: it occupies
    a single {!Sandbox_engine.Position.t} on the grid. Stepping onto its cell
    picks it up as an {!Item.Torch} in the player's {!Inventory}; a carried
    torch is placed back on a floor cell by its slot number. This module
    models only the on-map object and where it rests. {!Shield} is its
    mirror.

    {[
      let torch = Torch.create (Position.create ~row:2 ~col:5) in
      Item.equal (Torch.as_item torch) Item.Torch = true
    ]} *)

open! Core
open Sandbox_engine

type t [@@deriving sexp_of, compare, equal]

(** [create position] is a torch resting on [position]. *)
val create : Position.t -> t

(** [position t] is the cell [t] sits on. *)
val position : t -> Position.t

(** [is_at t position] is whether [t] rests on [position]. The game uses it
    to detect the player stepping onto the torch, the moment it is picked up. *)
val is_at : t -> Position.t -> bool

(** [as_item t] is the inventory item a picked-up torch becomes. *)
val as_item : t -> Item.t
