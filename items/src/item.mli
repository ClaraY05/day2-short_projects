(** An item the player can carry: a {!module-Torch} or a {!module-Shield}.

    This is what fills a slot in the {!Inventory}. On the map an item is a
    {!module-Torch} or {!module-Shield} resting on a cell; once picked up
    only its kind matters, which is all this variant records. Placing it back
    — see {!Inventory.place} — turns the kind into a fresh on-map object at
    the player's cell.

    {[
      Item.to_string Item.Torch = "torch"
    ]} *)

open! Core

type t =
  | Torch
  | Shield
[@@deriving sexp_of, compare, equal, enumerate]

(** [to_string t] is the lowercase name shown in the inventory bar, e.g.
    [torch]. *)
val to_string : t -> string
