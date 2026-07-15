open! Core
open Sandbox_engine

type intent =
  | Move of Direction.t
  | Confirm
[@@deriving sexp_of, compare, equal]

let intent_of_key key =
  match String.lowercase key with
  | "w" | "arrowup" -> Some (Move North)
  | "s" | "arrowdown" -> Some (Move South)
  | "a" | "arrowleft" -> Some (Move West)
  | "d" | "arrowright" -> Some (Move East)
  | "enter" | " " -> Some Confirm
  | _ -> None
;;

(* The lobby's difficulty book: a number key picks the preset at that
   position in [Difficulty.all], so ["1"] is the first listed. Keeping the
   mapping tied to [all] means the book's numbering and the keys never drift
   apart. *)
let difficulty_of_key key =
  match Int.of_string_opt key with
  | Some slot when slot >= 1 -> List.nth Difficulty.all (slot - 1)
  | Some _ | None -> None
;;
