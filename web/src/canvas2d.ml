open! Core
open Js_of_ocaml

type t = Dom_html.canvasRenderingContext2D Js.t

let n = Js.number_of_float

let context canvas =
  let ctx = canvas##getContext Dom_html._2d_ in
  (* [imageSmoothingEnabled] is not in the jsoo class type; set it raw. *)
  Js.Unsafe.set ctx (Js.string "imageSmoothingEnabled") Js._false;
  ctx
;;

let width (t : t) = Float.of_int t##.canvas##.width
let height (t : t) = Float.of_int t##.canvas##.height
let save (t : t) = t##save
let restore (t : t) = t##restore
let translate (t : t) ~x ~y = t##translate (n x) (n y)
let rotate (t : t) angle = t##rotate (n angle)
let scale (t : t) ~x ~y = t##scale (n x) (n y)
let set_alpha (t : t) alpha = t##.globalAlpha := n alpha

let set_shadow (t : t) ~color ~blur =
  t##.shadowColor := Js.string color;
  t##.shadowBlur := n blur
;;

let clear_shadow t = set_shadow t ~color:"transparent" ~blur:0.
let set_fill (t : t) color = t##.fillStyle := Js.string color
let fill_rect (t : t) ~x ~y ~w ~h = t##fillRect (n x) (n y) (n w) (n h)

let add_stops gradient stops =
  List.iter stops ~f:(fun (offset, color) ->
    gradient##addColorStop (n offset) (Js.string color))
;;

let linear_gradient (t : t) ~x0 ~y0 ~x1 ~y1 ~stops =
  let gradient = t##createLinearGradient (n x0) (n y0) (n x1) (n y1) in
  add_stops gradient stops;
  t##.fillStyle_gradient := gradient
;;

let radial_gradient (t : t) ~x ~y ~r0 ~r1 ~stops =
  let gradient =
    t##createRadialGradient (n x) (n y) (n r0) (n x) (n y) (n r1)
  in
  add_stops gradient stops;
  t##.fillStyle_gradient := gradient
;;

let begin_path (t : t) = t##beginPath
let close_path (t : t) = t##closePath
let move_to (t : t) ~x ~y = t##moveTo (n x) (n y)
let line_to (t : t) ~x ~y = t##lineTo (n x) (n y)

let quadratic_curve_to (t : t) ~cx ~cy ~x ~y =
  t##quadraticCurveTo (n cx) (n cy) (n x) (n y)
;;

let arc (t : t) ~x ~y ~r ~a0 ~a1 =
  t##arc (n x) (n y) (n r) (n a0) (n a1) Js._false
;;

let fill (t : t) = t##fill
let set_font (t : t) font = t##.font := Js.string font
let set_text_align (t : t) align = t##.textAlign := Js.string align
let fill_text (t : t) text ~x ~y = t##fillText (Js.string text) (n x) (n y)
