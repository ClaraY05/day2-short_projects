open! Core
open Sandbox_engine
module C = Canvas2d

let trader ~ctx ~x ~y ~facing ~now_ms ~moving ~scale ?(rotation = 0.) () =
  let bob =
    if moving
    then Float.abs (Float.sin (now_ms /. 110.)) *. 2.
    else Float.sin (now_ms /. 520.) *. 0.7
  in
  C.save ctx;
  C.translate ctx ~x ~y:(y -. ((13. +. bob) *. scale));
  C.rotate ctx rotation;
  C.scale ctx ~x:scale ~y:scale;
  C.set_shadow ctx ~color:Palette.trader_robe_bright ~blur:13.;
  C.set_fill ctx Palette.trader_robe;
  C.begin_path ctx;
  C.move_to ctx ~x:(-9.) ~y:13.;
  C.line_to ctx ~x:(-5.) ~y:(-1.);
  C.line_to ctx ~x:5. ~y:(-1.);
  C.line_to ctx ~x:9. ~y:13.;
  C.close_path ctx;
  C.fill ctx;
  C.set_fill ctx Palette.trader_robe_bright;
  C.fill_rect ctx ~x:(-6.) ~y:(-1.) ~w:12. ~h:3.;
  C.clear_shadow ctx;
  C.set_fill ctx Palette.trader_skin;
  C.fill_rect ctx ~x:(-6.) ~y:(-13.) ~w:12. ~h:12.;
  C.set_fill ctx Palette.trader_turban;
  C.fill_rect ctx ~x:(-7.) ~y:(-16.) ~w:14. ~h:5.;
  C.set_fill ctx Palette.trader_robe_bright;
  C.fill_rect ctx ~x:(-7.) ~y:(-11.) ~w:14. ~h:2.;
  let gaze =
    match (facing : Direction.t) with
    | East -> 2.
    | West -> -2.
    | North | South -> 0.
  in
  C.set_fill ctx Palette.trader_eyes;
  C.fill_rect ctx ~x:(-3. +. gaze) ~y:(-8.) ~w:2. ~h:3.;
  C.fill_rect ctx ~x:(2. +. gaze) ~y:(-8.) ~w:2. ~h:3.;
  C.restore ctx
;;

let camel ~ctx ~x ~y ~now_ms ~style ~scale =
  let body, belly, eye, flip, bob =
    match style with
    | `In_maze ->
      ( Palette.camel
      , Palette.banana_shade
      , "#5a3f07"
      , 1.
      , Float.sin (now_ms /. 280.) )
    | `Reunion ->
      "#e8b45c", "#c99433", "#3a2705", -1., Float.sin (now_ms /. 300.) *. 2.
  in
  C.save ctx;
  C.translate ctx ~x ~y:(y +. bob);
  C.scale ctx ~x:(flip *. scale) ~y:scale;
  C.set_shadow ctx ~color:Palette.camel ~blur:16.;
  C.set_fill ctx body;
  C.fill_rect ctx ~x:(-11.) ~y:(-2.) ~w:20. ~h:7.;
  C.fill_rect ctx ~x:(-8.) ~y:(-7.) ~w:7. ~h:6.;
  C.fill_rect ctx ~x:0. ~y:(-7.) ~w:7. ~h:6.;
  C.fill_rect ctx ~x:8. ~y:(-9.) ~w:4. ~h:9.;
  C.fill_rect ctx ~x:10. ~y:(-12.) ~w:6. ~h:4.;
  C.fill_rect ctx ~x:(-9.) ~y:5. ~w:3. ~h:6.;
  C.fill_rect ctx ~x:(-2.) ~y:5. ~w:3. ~h:6.;
  C.fill_rect ctx ~x:5. ~y:5. ~w:3. ~h:6.;
  C.clear_shadow ctx;
  C.set_fill ctx belly;
  C.fill_rect ctx ~x:(-11.) ~y:3. ~w:20. ~h:2.;
  C.set_fill ctx eye;
  C.fill_rect ctx ~x:13. ~y:(-11.) ~w:2. ~h:2.;
  C.restore ctx
;;

let beast ~ctx ~x ~y ~cell_size:s ~color =
  C.set_shadow ctx ~color ~blur:20.;
  C.set_fill ctx color;
  (* Horns. *)
  C.begin_path ctx;
  C.move_to ctx ~x:(x -. (s *. 0.34)) ~y:(y -. 6.);
  C.line_to ctx ~x:(x -. (s *. 0.26)) ~y:(y -. (s *. 0.42));
  C.line_to ctx ~x:(x -. (s *. 0.14)) ~y:(y -. 8.);
  C.fill ctx;
  C.begin_path ctx;
  C.move_to ctx ~x:(x +. (s *. 0.34)) ~y:(y -. 6.);
  C.line_to ctx ~x:(x +. (s *. 0.26)) ~y:(y -. (s *. 0.42));
  C.line_to ctx ~x:(x +. (s *. 0.14)) ~y:(y -. 8.);
  C.fill ctx;
  (* Dome and body. *)
  C.begin_path ctx;
  C.arc ctx ~x ~y:(y -. 2.) ~r:(s *. 0.34) ~a0:Float.pi ~a1:0.;
  C.fill ctx;
  C.fill_rect
    ctx
    ~x:(x -. (s *. 0.34))
    ~y:(y -. 2.)
    ~w:(s *. 0.68)
    ~h:(s *. 0.30);
  (* Ragged bottom. *)
  C.begin_path ctx;
  let w = s *. 0.68 in
  let x0 = x -. (s *. 0.34) in
  let yb = y -. 2. +. (s *. 0.30) in
  C.move_to ctx ~x:x0 ~y:yb;
  List.iter (List.range 0 4) ~f:(fun i ->
    let i = Float.of_int i in
    C.line_to ctx ~x:(x0 +. (w *. (i +. 0.5) /. 4.)) ~y:(yb +. 5.);
    C.line_to ctx ~x:(x0 +. (w *. (i +. 1.) /. 4.)) ~y:yb);
  C.fill ctx;
  C.clear_shadow ctx;
  (* Eyes. *)
  C.set_fill ctx "#fff";
  C.fill_rect ctx ~x:(x -. 9.) ~y:(y -. 7.) ~w:5. ~h:7.;
  C.fill_rect ctx ~x:(x +. 4.) ~y:(y -. 7.) ~w:5. ~h:7.;
  C.set_fill ctx "#111";
  C.fill_rect ctx ~x:(x -. 7.) ~y:(y -. 4.) ~w:3. ~h:4.;
  C.fill_rect ctx ~x:(x +. 6.) ~y:(y -. 4.) ~w:3. ~h:4.
;;

let banana ~ctx ~x ~y ~scale =
  C.save ctx;
  C.translate ctx ~x ~y;
  C.rotate ctx 0.5;
  C.scale ctx ~x:scale ~y:scale;
  C.set_fill ctx Palette.banana;
  C.fill_rect ctx ~x:(-10.) ~y:(-4.) ~w:20. ~h:8.;
  C.set_fill ctx Palette.banana_shade;
  C.fill_rect ctx ~x:(-10.) ~y:2. ~w:20. ~h:2.;
  C.set_fill ctx "#5a4207";
  C.fill_rect ctx ~x:9. ~y:(-4.) ~w:2. ~h:3.;
  C.restore ctx
;;

let dot ~ctx ~x ~y =
  C.set_fill ctx Palette.dot;
  C.fill_rect ctx ~x:(x -. 2.) ~y:(y -. 2.) ~w:4. ~h:4.
;;

let torch ~ctx ~x ~y =
  C.set_fill ctx "#7a4a1a";
  C.fill_rect ctx ~x:(x -. 2.) ~y ~w:4. ~h:10.;
  C.set_fill ctx "#ff8a2b";
  C.fill_rect ctx ~x:(x -. 4.) ~y:(y -. 8.) ~w:8. ~h:10.;
  C.set_fill ctx Palette.banana;
  C.fill_rect ctx ~x:(x -. 3.) ~y:(y -. 12.) ~w:6. ~h:6.
;;

let heart ~ctx ~x ~y ~size:s =
  C.set_fill ctx "#ff5a8a";
  C.fill_rect ctx ~x:(x -. s) ~y:(y -. s) ~w:s ~h:s;
  C.fill_rect ctx ~x ~y:(y -. s) ~w:s ~h:s;
  C.fill_rect ctx ~x:(x -. s -. 1.) ~y ~w:((s *. 2.) +. 1.) ~h:s;
  C.fill_rect
    ctx
    ~x:(x -. s +. 1.)
    ~y:(y +. s)
    ~w:((s *. 2.) -. 2.)
    ~h:(s *. 0.7);
  C.fill_rect ctx ~x:(x -. 1.) ~y:(y +. s +. 2.) ~w:2. ~h:2.
;;

let spark ~ctx ~x ~y ~color =
  C.set_fill ctx color;
  C.fill_rect ctx ~x:(x -. 2.) ~y:(y -. 2.) ~w:4. ~h:4.;
  C.fill_rect ctx ~x:(x -. 4.) ~y ~w:8. ~h:1.;
  C.fill_rect ctx ~x ~y:(y -. 4.) ~w:1. ~h:8.
;;
