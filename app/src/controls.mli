(** Keyboard bindings, matching the Camel O mockup.

    The map never rotates, so W/A/S/D and the arrows are absolute compass
    moves ({!Sandbox_engine.Game.Action.Move_absolute}); Enter and Space
    confirm (start a run, dismiss an end screen).

    {[
      Controls.intent_of_key "ArrowLeft" = Some (Move West)
    ]} *)

open! Core
open Sandbox_engine

type intent =
  | Move of Direction.t
  | Confirm
[@@deriving sexp_of, compare, equal]

(** [intent_of_key key] reads a DOM [KeyboardEvent.key] value
    (case-insensitive), e.g. ["w"], ["ArrowUp"], ["Enter"], [" "]. *)
val intent_of_key : string -> intent option

(** [difficulty_of_key key] reads a number-row [KeyboardEvent.key] (["1"],
    ["2"], ["3"], ...) as a pick from {!Sandbox_app.Difficulty.all} by
    position — ["1"] is the first preset. The lobby's difficulty book listens
    for these. *)
val difficulty_of_key : string -> Difficulty.t option
