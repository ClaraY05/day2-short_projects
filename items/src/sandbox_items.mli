(** Interactive items for {e Slip} and the inventory that holds them.

    Torches and shields are objects that rest on maze cells, like the key and
    bananas ({!Sandbox_engine.Position}). Stepping onto one picks it up into
    the {!Inventory}; pressing a slot number and Enter places it back on the
    map. This library is pure logic — the map, pickup, and key handling that
    tie it into play live in [sandbox.engine] and [sandbox.app]. *)

(** The player's carried items in numbered slots. *)
module Inventory = Inventory

(** What a carried item is: a torch or a shield. *)
module Item = Item

(** A pickable shield that rests on a maze cell. *)
module Shield = Shield

(** A pickable torch that rests on a maze cell. *)
module Torch = Torch
