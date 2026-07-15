open! Core
open Sandbox_app
module C = Canvas2d

let ground_y = 410.

type star =
  { star_x : float
  ; star_y : float
  ; star_size : float
  ; star_phase : float
  }

type peel =
  { peel_x : float
  ; peel_lift : float
  ; peel_rotation : float
  }

type scatter =
  { stars : star array
  ; spill : peel array
  }

let scatter ~random_state =
  let float = Random.State.float random_state in
  let stars =
    Array.init 70 ~f:(fun (_ : int) ->
      { star_x = float Lobby.world_width
      ; star_y = float 230.
      ; star_size = (if Float.( < ) (float 1.) 0.25 then 2. else 1.)
      ; star_phase = float 6.
      })
  in
  let spill =
    Array.init 30 ~f:(fun (_ : int) ->
      { peel_x = 640. +. float 640.
      ; peel_lift = float 16.
      ; peel_rotation = float Float.pi
      })
  in
  { stars; spill }
;;

let font size = [%string {|%{size#Int}px "Press Start 2P", monospace|}]

(* A rolling dune silhouette; [factor] is its parallax depth. *)
let dune_band ctx ~cam_x ~base_y ~amplitude ~frequency ~phase ~color ~factor =
  let width = C.width ctx in
  C.set_fill ctx color;
  C.begin_path ctx;
  C.move_to ctx ~x:0. ~y:(ground_y +. 40.);
  let x = ref 0. in
  while Float.( <= ) !x width do
    let world_x = !x +. (cam_x *. factor) in
    C.line_to
      ctx
      ~x:!x
      ~y:
        (base_y +. (Float.sin ((world_x *. frequency) +. phase) *. amplitude));
    x := !x +. 6.
  done;
  C.line_to ctx ~x:width ~y:(ground_y +. 40.);
  C.close_path ctx;
  C.fill ctx
;;

(* The gap the trader heads for — the dark opening and its warm pulse. Drawn
   behind the trader so he stands in front of the doorway as he nears it,
   then behind the flanking mounds ({!draw_entrance_front}). *)
let draw_entrance_back ctx ~x:ex ~now_ms =
  let g = ground_y in
  (* The dark opening. Its base meets the ground line, where the trader
     stands. *)
  C.set_fill ctx "#080503";
  C.fill_rect ctx ~x:(ex -. 30.) ~y:(g -. 120.) ~w:60. ~h:120.;
  C.begin_path ctx;
  C.arc ctx ~x:ex ~y:(g -. 120.) ~r:30. ~a0:Float.pi ~a1:0.;
  C.fill ctx;
  let pulse = 0.14 +. (0.07 *. Float.sin (now_ms /. 500.)) in
  C.radial_gradient
    ctx
    ~x:ex
    ~y:(g -. 32.)
    ~r0:4.
    ~r1:72.
    ~stops:
      [ 0., [%string "rgba(217,122,30,%{pulse +. 0.1#Float})"]
      ; 1., "rgba(217,122,30,0)"
      ];
  C.fill_rect ctx ~x:(ex -. 72.) ~y:(g -. 104.) ~w:144. ~h:144.
;;

(* The right-hand dune, painted behind the ground and the signpost so it
   reads as a hill rising further back rather than a mound in front of the
   camp. Its base meets the ground line, where the trader stands. *)
let draw_entrance_right_dune ctx ~x:ex =
  let g = ground_y in
  C.set_fill ctx "#3a1c0c";
  C.begin_path ctx;
  C.move_to ctx ~x:(ex +. 34.) ~y:g;
  C.quadratic_curve_to ctx ~cx:(ex +. 92.) ~cy:(g -. 222.) ~x:(ex +. 205.) ~y:g;
  C.fill ctx
;;

(* The left dune mound flanking the gap, the signpost, and the enter prompt.
   Drawn in front of the trader so the mound occludes him as he passes — a
   foreground hill hides what walks behind it. Its base runs past the ground
   line so it sits over the near sand. *)
let draw_entrance_front ctx ~x:ex ~now_ms ~can_enter =
  let g = ground_y in
  (* Left dune mound, beside the gap. *)
  C.set_fill ctx "#3a1c0c";
  C.begin_path ctx;
  C.move_to ctx ~x:(ex -. 195.) ~y:(g +. 40.);
  C.quadratic_curve_to
    ctx
    ~cx:(ex -. 82.)
    ~cy:(g -. 210.)
    ~x:(ex -. 34.)
    ~y:(g +. 40.);
  C.fill ctx;
  (* Signpost. *)
  C.set_fill ctx "#5a3a1a";
  C.fill_rect ctx ~x:(ex +. 62.) ~y:(g -. 56.) ~w:6. ~h:56.;
  C.set_fill ctx "#7a4a20";
  C.fill_rect ctx ~x:(ex +. 38.) ~y:(g -. 64.) ~w:70. ~h:20.;
  C.set_fill ctx "#3a2410";
  C.fill_rect ctx ~x:(ex +. 38.) ~y:(g -. 64.) ~w:70. ~h:3.;
  C.set_fill ctx "#ffcf7a";
  C.set_text_align ctx "center";
  C.set_font ctx (font 7);
  C.fill_text ctx "THE DUNES" ~x:(ex +. 73.) ~y:(g -. 51.);
  (* The enter prompt. *)
  let bounce = Float.sin (now_ms /. 300.) *. 4. in
  C.set_alpha ctx (if can_enter then 1. else 0.5);
  if can_enter
  then (
    C.radial_gradient
      ctx
      ~x:ex
      ~y:(g -. 152.)
      ~r0:4.
      ~r1:52.
      ~stops:[ 0., "rgba(255,226,74,0.32)"; 1., "rgba(255,226,74,0)" ];
    C.fill_rect ctx ~x:(ex -. 52.) ~y:(g -. 204.) ~w:104. ~h:104.);
  C.set_fill ctx Palette.title_yellow;
  C.set_font ctx (font 11);
  C.fill_text ctx "\xe2\x96\xb2 W" ~x:ex ~y:(g -. 170. +. bounce);
  C.set_fill ctx (if can_enter then "#fff2b0" else "#c9a24a");
  C.set_font ctx (font 7);
  C.fill_text ctx "ENTER THE DUNES" ~x:ex ~y:(g -. 154. +. bounce);
  C.set_alpha ctx 1.;
  C.set_text_align ctx "left"
;;

let draw_camp ctx ~x:cx ~now_ms =
  let g = ground_y in
  (* Tent. *)
  C.set_fill ctx "#a24632";
  C.begin_path ctx;
  C.move_to ctx ~x:(cx -. 48.) ~y:g;
  C.line_to ctx ~x:(cx -. 2.) ~y:(g -. 62.);
  C.line_to ctx ~x:(cx +. 44.) ~y:g;
  C.close_path ctx;
  C.fill ctx;
  C.set_fill ctx "#c25a40";
  C.begin_path ctx;
  C.move_to ctx ~x:(cx -. 2.) ~y:(g -. 62.);
  C.line_to ctx ~x:(cx +. 44.) ~y:g;
  C.line_to ctx ~x:(cx +. 14.) ~y:g;
  C.line_to ctx ~x:(cx -. 2.) ~y:(g -. 24.);
  C.close_path ctx;
  C.fill ctx;
  C.set_fill ctx "#2a140c";
  C.begin_path ctx;
  C.move_to ctx ~x:(cx -. 12.) ~y:g;
  C.line_to ctx ~x:(cx -. 2.) ~y:(g -. 30.);
  C.line_to ctx ~x:(cx +. 8.) ~y:g;
  C.close_path ctx;
  C.fill ctx;
  C.set_fill ctx "#e0b85a";
  C.fill_rect ctx ~x:(cx -. 3.) ~y:(g -. 66.) ~w:4. ~h:6.;
  (* Crate, to the right of the tent (the campfire took the left). *)
  C.set_fill ctx "#6a4420";
  C.fill_rect ctx ~x:(cx +. 56.) ~y:(g -. 20.) ~w:20. ~h:20.;
  C.set_fill ctx "#5a3818";
  C.fill_rect ctx ~x:(cx +. 56.) ~y:(g -. 20.) ~w:20. ~h:3.;
  C.fill_rect ctx ~x:(cx +. 64.) ~y:(g -. 20.) ~w:3. ~h:20.;
  (* Campfire, left of the tent; matches [Lobby.campfire_x], where the
     trader is stopped from walking any further left. *)
  let flicker = Float.sin (now_ms /. 80.) *. 3. in
  let fx = cx -. 74. in
  C.radial_gradient
    ctx
    ~x:fx
    ~y:(g -. 8.)
    ~r0:2.
    ~r1:56.
    ~stops:[ 0., "rgba(255,150,40,0.42)"; 1., "rgba(255,150,40,0)" ];
  C.fill_rect ctx ~x:(fx -. 56.) ~y:(g -. 64.) ~w:112. ~h:112.;
  C.set_fill ctx "#3a2410";
  C.fill_rect ctx ~x:(fx -. 12.) ~y:(g -. 4.) ~w:24. ~h:5.;
  C.set_fill ctx "#ff7a1a";
  C.begin_path ctx;
  C.move_to ctx ~x:(fx -. 8.) ~y:(g -. 4.);
  C.line_to ctx ~x:fx ~y:(g -. 24. -. flicker);
  C.line_to ctx ~x:(fx +. 8.) ~y:(g -. 4.);
  C.close_path ctx;
  C.fill ctx;
  C.set_fill ctx Palette.banana;
  C.begin_path ctx;
  C.move_to ctx ~x:(fx -. 4.) ~y:(g -. 4.);
  C.line_to ctx ~x:fx ~y:(g -. 16. -. (flicker *. 0.6));
  C.line_to ctx ~x:(fx +. 4.) ~y:(g -. 4.);
  C.close_path ctx;
  C.fill ctx
;;

let draw_truck ctx ~x:tx ~base_y ~scale =
  C.save ctx;
  C.translate ctx ~x:tx ~y:base_y;
  C.scale ctx ~x:scale ~y:scale;
  C.rotate ctx (-0.14);
  (* Tipped-over bed, wheels in the air. *)
  C.set_fill ctx "#cfa94e";
  C.fill_rect ctx ~x:(-74.) ~y:(-48.) ~w:112. ~h:48.;
  C.set_fill ctx "#e6c266";
  C.fill_rect ctx ~x:(-74.) ~y:(-48.) ~w:112. ~h:7.;
  C.set_fill ctx "#8a6a2a";
  C.fill_rect ctx ~x:(-74.) ~y:(-6.) ~w:112. ~h:6.;
  C.set_fill ctx "#b5482f";
  C.fill_rect ctx ~x:38. ~y:(-42.) ~w:36. ~h:42.;
  C.set_fill ctx "#d85a3a";
  C.fill_rect ctx ~x:38. ~y:(-42.) ~w:36. ~h:6.;
  C.set_fill ctx "#8ecae6";
  C.fill_rect ctx ~x:44. ~y:(-34.) ~w:22. ~h:15.;
  C.set_fill ctx "#1a1a1a";
  C.begin_path ctx;
  C.arc ctx ~x:(-42.) ~y:(-50.) ~r:10. ~a0:0. ~a1:(2. *. Float.pi);
  C.arc ctx ~x:6. ~y:(-50.) ~r:10. ~a0:0. ~a1:(2. *. Float.pi);
  C.arc ctx ~x:54. ~y:(-46.) ~r:9. ~a0:0. ~a1:(2. *. Float.pi);
  C.fill ctx;
  C.set_fill ctx "#555";
  C.begin_path ctx;
  C.arc ctx ~x:(-42.) ~y:(-50.) ~r:3. ~a0:0. ~a1:(2. *. Float.pi);
  C.arc ctx ~x:6. ~y:(-50.) ~r:3. ~a0:0. ~a1:(2. *. Float.pi);
  C.fill ctx;
  C.save ctx;
  C.translate ctx ~x:(-20.) ~y:(-24.);
  C.rotate ctx 0.4;
  C.set_fill ctx Palette.banana;
  C.fill_rect ctx ~x:(-10.) ~y:(-3.) ~w:20. ~h:7.;
  C.restore ctx;
  C.restore ctx
;;

(* The tipped banana truck, off on a dune in the background. Drawn before the
   ground so the near sand and the trader pass in front of it, and shrunk so
   it reads as distant. *)
let draw_truck_hill ctx ~x:tx =
  let g = ground_y in
  C.set_fill ctx "#6e3a1a";
  C.begin_path ctx;
  C.move_to ctx ~x:(tx -. 175.) ~y:(g +. 40.);
  C.quadratic_curve_to ctx ~cx:tx ~cy:(g -. 172.) ~x:(tx +. 175.) ~y:(g +. 40.);
  C.fill ctx;
  draw_truck ctx ~x:tx ~base_y:(g -. 66.) ~scale:0.6
;;

let draw ~ctx ~now_ms ~lobby ~scatter ~can_enter =
  let w = C.width ctx in
  let h = C.height ctx in
  let g = ground_y in
  let cam_x =
    Float.clamp_exn
      (Lobby.x lobby -. (w /. 2.))
      ~min:0.
      ~max:(Lobby.world_width -. w)
  in
  let on_screen world_x = Float.round_nearest (world_x -. cam_x) in
  (* Sunset sky. *)
  C.linear_gradient
    ctx
    ~x0:0.
    ~y0:0.
    ~x1:0.
    ~y1:(g +. 40.)
    ~stops:
      [ 0., "#170b26"
      ; 0.45, "#4a1f3a"
      ; 0.72, "#9c3f22"
      ; 0.9, "#d9782c"
      ; 1., "#eaa23e"
      ];
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h:(g +. 40.);
  (* Stars, drifting slower than the ground. *)
  Array.iter
    scatter.stars
    ~f:(fun { star_x; star_y; star_size; star_phase } ->
      let sx = star_x -. (cam_x *. 0.15) in
      if Float.( >= ) sx (-4.) && Float.( <= ) sx (w +. 4.)
      then (
        C.set_alpha
          ctx
          ((0.4
            +. (0.6 *. Float.abs (Float.sin ((now_ms /. 600.) +. star_phase)))
           )
           *. 0.9);
        C.set_fill ctx "#fff5d0";
        C.fill_rect
          ctx
          ~x:(Float.round_nearest sx)
          ~y:(Float.round_nearest star_y)
          ~w:star_size
          ~h:star_size));
  C.set_alpha ctx 1.;
  (* The low sun. *)
  let sun_x = 1200. -. (cam_x *. 0.3) in
  let sun_y = g -. 96. in
  C.radial_gradient
    ctx
    ~x:sun_x
    ~y:sun_y
    ~r0:6.
    ~r1:155.
    ~stops:
      [ 0., "rgba(255,222,145,0.85)"
      ; 0.4, "rgba(240,150,60,0.34)"
      ; 1., "rgba(240,150,60,0)"
      ];
  C.fill_rect ctx ~x:(sun_x -. 160.) ~y:(sun_y -. 160.) ~w:320. ~h:320.;
  C.set_fill ctx "#ffd98a";
  C.begin_path ctx;
  C.arc ctx ~x:sun_x ~y:sun_y ~r:40. ~a0:0. ~a1:(2. *. Float.pi);
  C.fill ctx;
  (* Far and near dunes. *)
  dune_band
    ctx
    ~cam_x
    ~base_y:(g -. 70.)
    ~amplitude:34.
    ~frequency:0.0016
    ~phase:0.
    ~color:"#7a3a1c"
    ~factor:0.35;
  dune_band
    ctx
    ~cam_x
    ~base_y:(g -. 36.)
    ~amplitude:26.
    ~frequency:0.0026
    ~phase:1.7
    ~color:"#5a2a12"
    ~factor:0.6;
  (* Background hills, before the ground and the trader paint in front: the
     truck's dune and the right entrance dune. *)
  draw_truck_hill ctx ~x:(on_screen Lobby.truck_x);
  draw_entrance_right_dune ctx ~x:(on_screen Lobby.entrance_x);
  (* Ground. *)
  C.linear_gradient
    ctx
    ~x0:0.
    ~y0:g
    ~x1:0.
    ~y1:h
    ~stops:[ 0., "#c88a3c"; 0.5, "#9c6526"; 1., "#5f3c15" ];
  C.fill_rect ctx ~x:0. ~y:g ~w ~h:(h -. g);
  C.set_fill ctx "#ffd98a";
  C.fill_rect ctx ~x:0. ~y:g ~w ~h:3.;
  (* Landmarks. The gap's dark mouth sits behind the trader; its flanking
     dune mounds are painted later, in front of him. *)
  draw_entrance_back ctx ~x:(on_screen Lobby.entrance_x) ~now_ms;
  draw_camp ctx ~x:(on_screen Lobby.camp_x) ~now_ms;
  Array.iter scatter.spill ~f:(fun { peel_x; peel_lift; peel_rotation } ->
    let px = on_screen peel_x in
    if Float.( >= ) px (-20.) && Float.( <= ) px (w +. 20.)
    then (
      C.save ctx;
      C.translate ctx ~x:px ~y:(g -. 3. -. (peel_lift *. 0.4));
      C.rotate ctx peel_rotation;
      C.set_fill ctx Palette.banana;
      C.fill_rect ctx ~x:(-6.) ~y:(-2.) ~w:12. ~h:5.;
      C.set_fill ctx Palette.banana_shade;
      C.fill_rect ctx ~x:(-6.) ~y:1. ~w:12. ~h:1.5;
      C.restore ctx));
  (* The trader, with a faint lantern aura. *)
  let trader_scale = 1.9 in
  let px = on_screen (Lobby.x lobby) in
  C.radial_gradient
    ctx
    ~x:px
    ~y:(g -. 24.)
    ~r0:8.
    ~r1:92.
    ~stops:[ 0., Palette.lantern_glow; 1., "rgba(120,220,255,0)" ];
  C.fill_rect ctx ~x:(px -. 92.) ~y:(g -. 116.) ~w:184. ~h:184.;
  Sprites.trader
    ~ctx
    ~x:px
    ~y:g
    ~facing:(Lobby.facing lobby)
    ~now_ms
    ~moving:(Lobby.is_walking lobby)
    ~scale:trader_scale
    ();
  (* The left dune mound and signpost, in front of the trader so he passes
     behind the mound instead of climbing over it. *)
  draw_entrance_front ctx ~x:(on_screen Lobby.entrance_x) ~now_ms ~can_enter;
  (* Title. *)
  C.set_text_align ctx "center";
  C.set_fill ctx Palette.title_yellow;
  C.set_shadow ctx ~color:"#a06b00" ~blur:18.;
  C.set_font ctx (font 26);
  C.fill_text ctx "CAMEL O" ~x:(w /. 2.) ~y:62.;
  C.clear_shadow ctx;
  C.set_fill ctx "rgba(255,214,120,0.72)";
  C.set_font ctx (font 8);
  C.fill_text ctx "a desert trader's search" ~x:(w /. 2.) ~y:82.;
  C.set_text_align ctx "left";
  (* Bottom fade, under the caption box. *)
  C.linear_gradient
    ctx
    ~x0:0.
    ~y0:(h -. 160.)
    ~x1:0.
    ~y1:h
    ~stops:[ 0., "rgba(0,0,0,0)"; 1., "rgba(0,0,0,0.5)" ];
  C.fill_rect ctx ~x:0. ~y:(h -. 160.) ~w ~h:160.
;;
