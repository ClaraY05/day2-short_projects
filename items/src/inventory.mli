(** The player's carried items, in numbered slots.

    A fixed row of {!num_slots} slots, numbered [1] through [9]. Stepping
    onto a {!Torch} or {!Shield} picks it up into the lowest free slot;
    pressing that slot's number key and Enter places the item back on the
    map. The renderer in [sandbox.app] draws the slot bar in the top-right of
    the screen and turns the number keys into {!place} calls; this module
    owns only the slots and the rules for filling and emptying them.

    {[
      let inventory = Inventory.add Inventory.empty Item.Torch |> ok_exn in
      Inventory.to_string_hum inventory
      = "[1:torch][2:-][3:-][4:-][5:-][6:-][7:-][8:-][9:-]"
    ]} *)

open! Core

type t [@@deriving sexp_of, compare, equal]

(** Slots are numbered [1] through [num_slots]. *)
val num_slots : int

(** An inventory with every slot empty. *)
val empty : t

(** [items t] is the contents of every slot in order, [None] for empty ones.
    The array has length {!num_slots}; index [i] holds slot [i + 1]. *)
val items : t -> Item.t option array

(** [is_full t] is whether every slot is taken, so nothing more can be picked
    up. *)
val is_full : t -> bool

(** [add t item] puts [item] in the lowest-numbered free slot, the effect of
    stepping onto it. Errors when the inventory {!is_full}. *)
val add : t -> Item.t -> t Or_error.t

(** [place t ~slot] removes and returns the item in [slot] — the effect of
    pressing the slot's number and Enter to drop it on the map. Errors when
    [slot] is outside [1 .. num_slots] or already empty. *)
val place : t -> slot:int -> (t * Item.t) Or_error.t

(** [to_string_hum t] is the one-line slot bar drawn in the top-right corner,
    e.g. [[1:torch][2:shield][3:-] ...]. *)
val to_string_hum : t -> string
