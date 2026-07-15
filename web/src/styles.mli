(** Style tokens for the vdom chrome around the canvas — the console frame,
    HUD, caption box and end screens, all lifted from the Camel O mockup.

    Every value is a ready-to-splice [Vdom.Attr.t] built with
    [Vdom.Attr.create "style" ...] (this project has no [ppx_css]); keeping
    them here keeps colors and spacing consistent with {!Palette}. *)

open! Core
open Bonsai_web

(** full-viewport centering, starfield backdrop *)
val page : Vdom.Attr.t

(** the 720px stack *)
val column : Vdom.Attr.t

val header_row : Vdom.Attr.t
val header_title : Vdom.Attr.t

(** the glowing CRT frame around the canvas *)
val console : Vdom.Attr.t

(** the overlayed CRT stripes *)
val scanlines : Vdom.Attr.t

val footer : Vdom.Attr.t

(** Playing HUD *)

val hud_bar : Vdom.Attr.t
val hud_stats : Vdom.Attr.t
val hud_goal : Vdom.Attr.t
val hud_slips_value : Vdom.Attr.t
val hud_score_value : Vdom.Attr.t
val hud_quit_button : Vdom.Attr.t

(** Lobby caption box *)

val caption_area : Vdom.Attr.t
val caption_tab : Vdom.Attr.t
val caption_tab_text : Vdom.Attr.t
val caption_box : Vdom.Attr.t
val caption_text : Vdom.Attr.t
val caption_hint : Vdom.Attr.t

(** Lobby difficulty book *)

val book_area : Vdom.Attr.t
val book_panel : Vdom.Attr.t
val book_title : Vdom.Attr.t
val book_rows : Vdom.Attr.t

(** [book_row], [book_slot] and [book_label] brighten when [is_selected] to
    mark the chosen preset. *)
val book_row : is_selected:bool -> Vdom.Attr.t

val book_slot : is_selected:bool -> Vdom.Attr.t
val book_label : is_selected:bool -> Vdom.Attr.t
val book_hint : Vdom.Attr.t

(** End screens *)

val overlay_won : Vdom.Attr.t
val overlay_lost : Vdom.Attr.t
val won_title : Vdom.Attr.t

(** pulses via the host page's keyframes *)
val lost_title : Vdom.Attr.t

val won_stats : Vdom.Attr.t
val lost_stats : Vdom.Attr.t
val button_row : Vdom.Attr.t

(** [primary_button ~fill] is the solid end-screen button (win green or beast
    red); [ghost_button] the outlined QUIT next to it. *)
val primary_button : fill:string -> Vdom.Attr.t

val ghost_button : Vdom.Attr.t
