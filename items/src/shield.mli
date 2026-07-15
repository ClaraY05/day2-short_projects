(** A shield: a pickable defensive item that sits on a maze cell.

    A shield mirrors {!Torch}: it is an interactable object occupying a
    single {!Sandbox_engine.Position.t}, like the key and bananas. Stepping
    onto its cell picks it up as an {!Item.Shield} in the player's
    {!Inventory}; a carried shield is placed back on a floor cell by its slot
    number. This module models only the on-map object and where it rests.

    {[
      let shield = Shield.create (Position.create ~row:1 ~col:3) in
      Item.equal (Shield.as_item shield) Item.Shield = true
    ]} *)

open! Core
open Sandbox_engine

type t [@@deriving sexp_of, compare, equal]

(** [create position] is a shield resting on [position]. *)
val create : Position.t -> t

(** [position t] is the cell [t] sits on. *)
val position : t -> Position.t

(** [is_at t position] is whether [t] rests on [position]. The game uses it
    to detect the player stepping onto the shield, the moment it is picked
    up. *)
val is_at : t -> Position.t -> bool

(** [as_item t] is the inventory item a picked-up shield becomes. *)
val as_item : t -> Item.t
