open! Core
open Sandbox_engine

type t =
  | Easy
  | Normal
  | Nightmare
[@@deriving sexp_of, compare, equal, enumerate]

let default = Normal

type config =
  { rows : int
  ; cols : int
  ; num_bananas : int
  ; cone_degrees : float
  ; view_cells : float
  ; monster : (module Monster.S)
  ; monster_cells_per_second : float
  }

(* The banana counts and beam shapes are the mockup's numbers; a 31x31
   cell-wall maze has about as many floor cells as the mockup's 21x21
   edge-wall grid, so the densities carry over. *)
let config = function
  | Easy ->
    { rows = 31
    ; cols = 31
    ; num_bananas = 9
    ; cone_degrees = 46.
    ; view_cells = 7.
    ; monster = (module Monster.Chaser : Monster.S)
    ; monster_cells_per_second = 2.7
    }
  | Normal ->
    { rows = 31
    ; cols = 31
    ; num_bananas = 16
    ; cone_degrees = 40.
    ; view_cells = 6.
    ; monster = (module Monster.Prowler : Monster.S)
    ; monster_cells_per_second = 3.6
    }
  | Nightmare ->
    { rows = 31
    ; cols = 31
    ; num_bananas = 24
    ; cone_degrees = 32.
    ; view_cells = 5.
    ; monster = (module Monster.Sprinter : Monster.S)
    ; monster_cells_per_second = 4.7
    }
;;

let torch_cone_bonus_degrees = 16.
let torch_view_bonus_cells = 3.
