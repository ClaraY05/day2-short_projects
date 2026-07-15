(** What the player is carrying.

    For now the only thing worth carrying is torches, picked up by stepping
    onto a {!Torch} and spent by placing one back on the map. The renderer in
    [sandbox.app] shows the count in the top-right corner of the screen; this
    module owns only the count and the rules for changing it.

    {[
      let inventory = Inventory.add_torch Inventory.empty in
      Inventory.torches inventory = 1
    ]} *)

open! Core

type t [@@deriving sexp_of, compare, equal]

(** An inventory holding nothing. *)
val empty : t

(** [torches t] is how many torches the player is carrying. *)
val torches : t -> int

(** [has_torch t] is whether the player has at least one torch to place. *)
val has_torch : t -> bool

(** [add_torch t] records one more torch, the effect of stepping onto one. *)
val add_torch : t -> t

(** [remove_torch t] spends one torch, the effect of placing it on the map.
    Errors when the player has none to place. *)
val remove_torch : t -> t Or_error.t

(** [to_string_hum t] is the one-line HUD summary drawn in the top-right
    corner, e.g. [Torches: 3]. *)
val to_string_hum : t -> string
