(** The Camel O color scheme, shared by the canvas painters and the vdom
    chrome in {!App} so both halves of the screen agree.

    Names follow what the design uses each color for rather than what it
    looks like, e.g. [beast] is the monster's neon red and [wall] the amber
    maze walls. *)

open! Core

(** canvas clear color, near-black blue *)
val void : string

(** maze floor *)
val floor_dark : string

(** maze wall strips, console glow *)
val wall : string

(** bright top edge of wall strips *)
val wall_highlight : string

(** monster + lose accents, neon red *)
val beast : string

(** banana yellow *)
val banana : string

val banana_shade : string

(** camel O gold *)
val camel : string

(** score pellet brown *)
val dot : string

(** victory green *)
val win : string

(** dim HUD gray-blue *)
val hud_text : string

val hud_accent_gold : string

(** PTS indigo *)
val score : string

val trader_robe : string
val trader_robe_bright : string
val trader_skin : string
val trader_turban : string
val trader_eyes : string
val lantern_glow : string

(** selection/title yellow *)
val title_yellow : string
