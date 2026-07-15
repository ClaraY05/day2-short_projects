(** A plain-[float] face over the js_of_ocaml 2D canvas context.

    Every wrapped call converts to [Js.number_t] in one place so the painters
    ({!Lobby_scene}, {!Maze_scene}, {!Cutscene_scene}) read like the
    Claude-design mockups they port. Only what those painters use is wrapped.

    {[
      Canvas2d.set_fill ctx "#04040a";
      Canvas2d.fill_rect ctx ~x:0. ~y:0. ~w:720. ~h:560.
    ]} *)

open! Core
open Js_of_ocaml

type t = Dom_html.canvasRenderingContext2D Js.t

(** [context canvas] is the 2d context, with image smoothing left off so
    scaled pixel art stays crisp. *)
val context : Dom_html.canvasElement Js.t -> t

val width : t -> float
val height : t -> float

(** State *)

val save : t -> unit
val restore : t -> unit
val translate : t -> x:float -> y:float -> unit
val rotate : t -> float -> unit
val scale : t -> x:float -> y:float -> unit
val set_alpha : t -> float -> unit
val set_shadow : t -> color:string -> blur:float -> unit
val clear_shadow : t -> unit

(** Fills *)

val set_fill : t -> string -> unit
val fill_rect : t -> x:float -> y:float -> w:float -> h:float -> unit

(** [linear_gradient t ~x0 ~y0 ~x1 ~y1 ~stops] sets the fill style to a
    linear gradient; [stops] are [(offset, color)] pairs. [radial_gradient]
    likewise between two circles around [(x, y)]. *)
val linear_gradient
  :  t
  -> x0:float
  -> y0:float
  -> x1:float
  -> y1:float
  -> stops:(float * string) list
  -> unit

val radial_gradient
  :  t
  -> x:float
  -> y:float
  -> r0:float
  -> r1:float
  -> stops:(float * string) list
  -> unit

(** Paths *)

val begin_path : t -> unit
val close_path : t -> unit
val move_to : t -> x:float -> y:float -> unit
val line_to : t -> x:float -> y:float -> unit

val quadratic_curve_to
  :  t
  -> cx:float
  -> cy:float
  -> x:float
  -> y:float
  -> unit

val arc : t -> x:float -> y:float -> r:float -> a0:float -> a1:float -> unit
val fill : t -> unit

(** Text *)

val set_font : t -> string -> unit
val set_text_align : t -> string -> unit
val fill_text : t -> string -> x:float -> y:float -> unit
