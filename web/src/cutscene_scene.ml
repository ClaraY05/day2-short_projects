open! Core
open Sandbox_app
module C = Canvas2d

let font size = [%string {|%{size#Int}px "Press Start 2P", monospace|}]

type sparkle =
  { spark_x : float
  ; spark_y : float
  ; spark_phase : float
  ; spark_size : float
  }

type support =
  { scramble : (int * int) array (* tile reveal order, pre-shuffled *)
  ; sparkles : sparkle array
  }

let scramble_cols = 15
let scramble_rows = 11

let support ~random_state =
  let scramble =
    List.cartesian_product
      (List.range 0 scramble_cols)
      (List.range 0 scramble_rows)
    |> List.permute ~random_state
    |> Array.of_list
  in
  let float = Random.State.float random_state in
  let sparkles =
    Array.init 40 ~f:(fun (_ : int) ->
      { spark_x = float 1.
      ; spark_y = float 1.
      ; spark_phase = float 6.
      ; spark_size = (if Float.( < ) (float 1.) 0.3 then 2. else 1.)
      })
  in
  { scramble; sparkles }
;;

(* The bigger, squashable banana of the pratfall. *)
let flat_banana ctx ~x ~y ~squash =
  if Float.( > ) squash 0.
  then (
    C.save ctx;
    C.translate ctx ~x ~y:(y -. 6.);
    C.scale ctx ~x:1. ~y:squash;
    C.rotate ctx 0.4;
    C.set_fill ctx Palette.banana;
    C.fill_rect ctx ~x:(-16.) ~y:(-6.) ~w:32. ~h:12.;
    C.set_fill ctx Palette.banana_shade;
    C.fill_rect ctx ~x:(-16.) ~y:3. ~w:32. ~h:3.;
    C.set_fill ctx "#5a4207";
    C.fill_rect ctx ~x:15. ~y:(-6.) ~w:3. ~h:4.;
    C.restore ctx)
;;

let slip_floor ctx ~ground_y =
  let w = C.width ctx in
  let h = C.height ctx in
  C.linear_gradient
    ctx
    ~x0:0.
    ~y0:0.
    ~x1:0.
    ~y1:ground_y
    ~stops:[ 0., "#2a1636"; 1., "#8a3f22" ];
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h:ground_y;
  C.linear_gradient
    ctx
    ~x0:0.
    ~y0:ground_y
    ~x1:0.
    ~y1:h
    ~stops:[ 0., "#c88a3c"; 1., "#5f3c15" ];
  C.fill_rect ctx ~x:0. ~y:ground_y ~w ~h:(h -. ground_y);
  C.set_fill ctx "#ffd98a";
  C.fill_rect ctx ~x:0. ~y:ground_y ~w ~h:3.;
  C.set_fill ctx "rgba(90,60,20,.5)";
  let x = ref (-20.) in
  while Float.( < ) !x w do
    C.fill_rect ctx ~x:!x ~y:(ground_y +. 8.) ~w:2. ~h:(h -. ground_y);
    x := !x +. 40.
  done
;;

let dizzy_stars ctx ~x ~y ~now_ms =
  List.iter (List.range 0 5) ~f:(fun i ->
    let angle = (now_ms /. 150.) +. (Float.of_int i *. 1.3) in
    Sprites.spark
      ~ctx
      ~x:(x +. (Float.cos angle *. 26.))
      ~y:(y +. (Float.sin angle *. 13.))
      ~color:Palette.title_yellow)
;;

let whoop ctx ~x ~y ~p =
  C.save ctx;
  C.translate ctx ~x ~y;
  let s = 1. +. (Float.sin (p *. Float.pi) *. 0.4) in
  C.scale ctx ~x:s ~y:s;
  C.set_text_align ctx "center";
  C.set_fill ctx "#ff7a1a";
  C.set_shadow ctx ~color:Palette.banana ~blur:12.;
  C.set_font ctx (font 20);
  C.fill_text ctx "WHOOP!" ~x:0. ~y:0.;
  C.restore ctx;
  C.set_text_align ctx "left"
;;

let scramble ctx ~support ~p ~now_ms =
  let w = C.width ctx in
  let h = C.height ctx in
  let tile_w = w /. Float.of_int scramble_cols in
  let tile_h = (h -. 90.) /. Float.of_int scramble_rows in
  let total = Array.length support.scramble in
  let shown =
    Int.min
      total
      (Int.of_float (Float.of_int total *. Float.min 1. (p *. 1.3)))
  in
  List.iter (List.range 0 shown) ~f:(fun i ->
    let tx, ty = support.scramble.(i) in
    let x = Float.of_int tx *. tile_w in
    let y = (Float.of_int ty *. tile_h) +. 20. in
    let wobble =
      Float.sin ((now_ms /. 200.) +. Float.of_int tx +. Float.of_int ty)
      *. 2.
    in
    C.set_fill ctx Palette.floor_dark;
    C.fill_rect
      ctx
      ~x:(x +. 2.)
      ~y:(y +. 2.)
      ~w:(tile_w -. 4.)
      ~h:(tile_h -. 4.);
    C.set_fill ctx Palette.wall;
    C.fill_rect ctx ~x:(x +. 2.) ~y:(y +. 2.) ~w:(tile_w -. 4.) ~h:4.;
    C.fill_rect ctx ~x:(x +. 2.) ~y:(y +. 2.) ~w:4. ~h:(tile_h -. 4.);
    C.set_fill ctx Palette.wall_highlight;
    C.fill_rect
      ctx
      ~x:(x +. 2.)
      ~y:(y +. 2. +. wobble)
      ~w:(tile_w -. 4.)
      ~h:2.)
;;

let draw_banana_slip ctx ~t ~now_ms ~support =
  let w = C.width ctx in
  let h = C.height ctx in
  let ground_y = h *. 0.62 in
  let cx = w /. 2. in
  let banana_x = cx +. 34. in
  if Float.( < ) t 3.4
  then slip_floor ctx ~ground_y
  else (
    C.set_fill ctx "#050303";
    C.fill_rect ctx ~x:0. ~y:0. ~w ~h);
  if Float.( < ) t 1.4
  then (
    (* The stroll toward doom. *)
    let p = t /. 1.4 in
    flat_banana ctx ~x:banana_x ~y:ground_y ~squash:1.;
    Sprites.trader
      ~ctx
      ~x:(140. +. ((cx -. 140.) *. p))
      ~y:ground_y
      ~facing:East
      ~now_ms
      ~moving:true
      ~scale:2.4
      ())
  else if Float.( < ) t 2.6
  then (
    (* The spin. *)
    let p = (t -. 1.4) /. 1.2 in
    flat_banana ctx ~x:banana_x ~y:ground_y ~squash:(1. -. (p *. 0.8));
    let spin = p *. Float.pi *. 6. in
    let hop = Float.sin (p *. Float.pi) *. 70. in
    Sprites.trader
      ~ctx
      ~x:(cx +. (p *. 40.))
      ~y:(ground_y -. hop)
      ~facing:East
      ~now_ms
      ~moving:true
      ~scale:2.4
      ~rotation:spin
      ();
    dizzy_stars ctx ~x:(cx +. (p *. 40.)) ~y:(ground_y -. hop -. 46.) ~now_ms;
    whoop ctx ~x:cx ~y:(ground_y -. 120. -. (hop *. 0.4)) ~p);
  if Float.( >= ) t 2.4 && Float.( < ) t 3.4
  then (
    (* Whiteout, then dark. *)
    let p = t -. 2.4 in
    C.set_fill
      ctx
      [%string "rgba(255,255,255,%{Float.max 0. (0.7 -. (p *. 3.))#Float})"];
    C.fill_rect ctx ~x:0. ~y:0. ~w ~h;
    C.set_fill ctx [%string "rgba(4,3,2,%{Float.min 1. (p *. 1.6)#Float})"];
    C.fill_rect ctx ~x:0. ~y:0. ~w ~h;
    if Float.( > ) p 0.4
    then (
      C.set_text_align ctx "center";
      C.set_fill ctx Palette.title_yellow;
      C.set_font ctx (font 18);
      C.fill_text ctx "you slipped..." ~x:cx ~y:ground_y;
      C.set_text_align ctx "left"));
  if Float.( >= ) t 3.4
  then (
    (* The dunes shift: the new maze tiles wobble in. *)
    let p = (t -. 3.4) /. 1.4 in
    scramble ctx ~support ~p ~now_ms;
    C.set_text_align ctx "center";
    C.set_fill ctx Palette.hud_text;
    C.set_font ctx (font 10);
    C.fill_text ctx "the dunes shift beneath you" ~x:cx ~y:(h -. 52.);
    C.set_text_align ctx "left")
;;

let jumpscare_buildup ctx ~p ~t =
  let w = C.width ctx in
  let h = C.height ctx in
  let cx = w /. 2. in
  let cy = h /. 2. in
  let heartbeat =
    0.12 +. (0.5 *. p *. (0.55 +. (0.45 *. Float.sin (t *. 16.))))
  in
  C.radial_gradient
    ctx
    ~x:cx
    ~y:cy
    ~r0:(h *. 0.15)
    ~r1:(h *. 0.72)
    ~stops:
      [ 0., "rgba(120,0,20,0)"
      ; 1., [%string "rgba(160,0,25,%{heartbeat#Float})"]
      ];
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h;
  let s = 8. +. (p *. 46.) in
  let gap = s *. 1.5 in
  let jitter = (1. -. p) *. 7. in
  let ox = Float.sin (t *. 9.) *. jitter in
  C.save ctx;
  C.set_shadow ctx ~color:Palette.beast ~blur:(18. +. (p *. 34.));
  (* A silhouette condensing out of the dark. *)
  C.set_alpha ctx (0.12 +. (p *. 0.4));
  C.set_fill ctx Palette.beast;
  C.begin_path ctx;
  C.arc ctx ~x:(cx +. ox) ~y:(cy +. s) ~r:(s *. 2.6) ~a0:Float.pi ~a1:0.;
  C.fill ctx;
  C.fill_rect
    ctx
    ~x:(cx +. ox -. (s *. 2.6))
    ~y:(cy +. s)
    ~w:(s *. 5.2)
    ~h:(s *. 2.6);
  C.set_alpha ctx 1.;
  (* Eyes first. *)
  C.set_fill ctx "#fff";
  C.fill_rect
    ctx
    ~x:(cx +. ox -. gap -. (s /. 2.))
    ~y:(cy -. (s /. 2.))
    ~w:s
    ~h:(s *. 1.2);
  C.fill_rect
    ctx
    ~x:(cx +. ox +. gap -. (s /. 2.))
    ~y:(cy -. (s /. 2.))
    ~w:s
    ~h:(s *. 1.2);
  C.clear_shadow ctx;
  C.set_fill ctx Palette.beast;
  let pupil = s *. 0.4 in
  C.fill_rect
    ctx
    ~x:(cx +. ox -. gap -. (pupil /. 2.))
    ~y:(cy +. 2.)
    ~w:pupil
    ~h:(pupil *. 1.3);
  C.fill_rect
    ctx
    ~x:(cx +. ox +. gap -. (pupil /. 2.))
    ~y:(cy +. 2.)
    ~w:pupil
    ~h:(pupil *. 1.3);
  C.restore ctx;
  C.set_fill
    ctx
    [%string
      "rgba(210,160,160,%{0.28 +. (0.3 *. Float.sin (t *. 10.))#Float})"];
  C.set_text_align ctx "center";
  C.set_font ctx (font 9);
  C.fill_text ctx "something moves in the dark..." ~x:cx ~y:(h -. 64.);
  C.set_text_align ctx "left"
;;

let jumpscare_face ctx ~prog ~random_state =
  let w = C.width ctx in
  let h = C.height ctx in
  let flash = Float.( > ) (Random.State.float random_state 1.) 0.5 in
  C.set_fill ctx (if flash then "#c1001f" else "#0a0000");
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h;
  let cx = w /. 2. in
  let cy = h /. 2. in
  let sz = Float.min w h *. (0.5 +. (prog *. 0.42)) in
  C.save ctx;
  C.set_shadow ctx ~color:Palette.beast ~blur:45.;
  C.set_fill ctx Palette.beast;
  (* Spiky crown over a round face. *)
  C.begin_path ctx;
  List.iter (List.range 0 10) ~f:(fun i ->
    let angle = Float.pi +. (Float.pi *. Float.of_int i /. 9.) in
    let radius = (sz *. 0.52) +. if i % 2 = 1 then 8. else 0. in
    C.line_to
      ctx
      ~x:(cx +. (Float.cos angle *. radius))
      ~y:(cy -. (sz *. 0.14) +. (Float.sin angle *. radius *. 0.5)));
  C.arc ctx ~x:cx ~y:cy ~r:(sz *. 0.5) ~a0:0. ~a1:Float.pi;
  C.fill ctx;
  C.clear_shadow ctx;
  C.set_fill ctx "#fff";
  C.fill_rect
    ctx
    ~x:(cx -. (sz *. 0.30))
    ~y:(cy -. (sz *. 0.20))
    ~w:(sz *. 0.20)
    ~h:(sz *. 0.24);
  C.fill_rect
    ctx
    ~x:(cx +. (sz *. 0.10))
    ~y:(cy -. (sz *. 0.20))
    ~w:(sz *. 0.20)
    ~h:(sz *. 0.24);
  let jx = (Random.State.float random_state 1. -. 0.5) *. 10. in
  C.set_fill ctx "#000";
  C.fill_rect
    ctx
    ~x:(cx -. (sz *. 0.24) +. jx)
    ~y:(cy -. (sz *. 0.12))
    ~w:(sz *. 0.09)
    ~h:(sz *. 0.12);
  C.fill_rect
    ctx
    ~x:(cx +. (sz *. 0.16) +. jx)
    ~y:(cy -. (sz *. 0.12))
    ~w:(sz *. 0.09)
    ~h:(sz *. 0.12);
  (* Zigzag maw. *)
  C.set_fill ctx "#0a0000";
  C.begin_path ctx;
  let mw = sz *. 0.54 in
  let mx = cx -. (sz *. 0.27) in
  let my = cy +. (sz *. 0.10) in
  C.move_to ctx ~x:mx ~y:my;
  List.iter (List.range 0 7) ~f:(fun i ->
    let i = Float.of_int i in
    C.line_to
      ctx
      ~x:(mx +. (mw *. i /. 6.))
      ~y:(my +. if Int.of_float i % 2 = 1 then sz *. 0.17 else 0.));
  C.line_to ctx ~x:(mx +. mw) ~y:(my +. (sz *. 0.24));
  C.line_to ctx ~x:mx ~y:(my +. (sz *. 0.24));
  C.fill ctx;
  C.restore ctx;
  if Float.( > ) prog 0.35
  then (
    C.set_text_align ctx "center";
    C.set_fill ctx "#fff";
    C.set_shadow ctx ~color:Palette.beast ~blur:20.;
    C.set_font ctx (font 40);
    C.fill_text ctx "MAULED" ~x:cx ~y:(h -. 52.);
    C.clear_shadow ctx;
    C.set_text_align ctx "left")
;;

let draw_jumpscare ctx ~t ~random_state =
  let w = C.width ctx in
  let h = C.height ctx in
  C.set_fill ctx "#050203";
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h;
  if Float.( < ) t 1.4
  then jumpscare_buildup ctx ~p:(t /. 1.4) ~t
  else if Float.( < ) t 2.8
  then jumpscare_face ctx ~prog:((t -. 1.4) /. 1.4) ~random_state
  else (
    jumpscare_face ctx ~prog:1. ~random_state;
    C.set_fill
      ctx
      [%string "rgba(3,1,2,%{Float.min 1. ((t -. 2.8) /. 0.8)#Float})"];
    C.fill_rect ctx ~x:0. ~y:0. ~w ~h)
;;

let draw_finding_o ctx ~t ~now_ms ~support =
  let w = C.width ctx in
  let h = C.height ctx in
  let ground_y = h *. 0.66 in
  let mid_x = w *. 0.56 in
  let camel_x = w *. 0.6 in
  (* Dawn. *)
  C.linear_gradient
    ctx
    ~x0:0.
    ~y0:0.
    ~x1:0.
    ~y1:ground_y
    ~stops:[ 0., "#2a4a7a"; 0.5, "#e08a5a"; 1., "#ffcf8a" ];
  C.fill_rect ctx ~x:0. ~y:0. ~w ~h:ground_y;
  (* Slowly wheeling god-rays. *)
  C.save ctx;
  C.translate ctx ~x:camel_x ~y:(ground_y -. 70.);
  C.set_alpha ctx 0.16;
  C.set_fill ctx "#fff2c0";
  List.iter (List.range 0 12) ~f:(fun (_ : int) ->
    C.rotate ctx ((Float.pi /. 6.) +. (now_ms /. 4000.));
    C.begin_path ctx;
    C.move_to ctx ~x:0. ~y:0.;
    C.line_to ctx ~x:(-16.) ~y:(-460.);
    C.line_to ctx ~x:16. ~y:(-460.);
    C.fill ctx);
  C.restore ctx;
  C.radial_gradient
    ctx
    ~x:camel_x
    ~y:(ground_y -. 70.)
    ~r0:8.
    ~r1:120.
    ~stops:[ 0., "rgba(255,240,190,0.8)"; 1., "rgba(255,240,190,0)" ];
  C.fill_rect ctx ~x:(camel_x -. 120.) ~y:(ground_y -. 190.) ~w:240. ~h:240.;
  (* Ground. *)
  C.linear_gradient
    ctx
    ~x0:0.
    ~y0:ground_y
    ~x1:0.
    ~y1:h
    ~stops:[ 0., "#d8a552"; 1., "#7a4e1e" ];
  C.fill_rect ctx ~x:0. ~y:ground_y ~w ~h:(h -. ground_y);
  C.set_fill ctx "#fff0c0";
  C.fill_rect ctx ~x:0. ~y:ground_y ~w ~h:3.;
  (* Camel O waits in the light. *)
  Sprites.camel
    ~ctx
    ~x:camel_x
    ~y:(ground_y -. (13. *. 2.6))
    ~now_ms
    ~style:`Reunion
    ~scale:2.6;
  (* The trader walks in. *)
  let walk = Float.min 1. (t /. 1.6) in
  let trader_x = 100. +. ((mid_x -. 100.) *. walk) in
  Sprites.trader
    ~ctx
    ~x:trader_x
    ~y:ground_y
    ~facing:East
    ~now_ms
    ~moving:(Float.( < ) walk 0.98)
    ~scale:2.4
    ();
  (* Hearts and sparkles once they meet. *)
  if Float.( > ) t 1.5
  then (
    let met = t -. 1.5 in
    List.iter (List.range 0 6) ~f:(fun i ->
      let i = Float.of_int i in
      let rise = Float.mod_float ((met *. 0.6) +. (i /. 6.)) 1. in
      let hx =
        ((trader_x +. camel_x) /. 2.) +. (Float.sin ((i *. 2.) +. met) *. 30.)
      in
      let hy = ground_y -. 40. -. (rise *. 130.) in
      C.set_alpha ctx (Float.max 0. (1. -. rise));
      Sprites.heart ~ctx ~x:hx ~y:hy ~size:(4. +. ((1. -. rise) *. 3.)));
    C.set_alpha ctx 1.;
    Array.iter
      support.sparkles
      ~f:(fun { spark_x; spark_y; spark_phase; spark_size } ->
        let pp = Float.mod_float ((now_ms /. 900.) +. spark_phase) 1. in
        C.set_alpha ctx ((1. -. pp) *. 0.9);
        C.set_fill ctx "#fff2c0";
        C.fill_rect
          ctx
          ~x:(camel_x -. 120. +. (spark_x *. 240.))
          ~y:(ground_y -. 160. +. (spark_y *. 150.) -. (pp *. 20.))
          ~w:spark_size
          ~h:spark_size);
    C.set_alpha ctx 1.);
  (* Title pop-in. *)
  if Float.( > ) t 1.9
  then (
    let p = Float.min 1. ((t -. 1.9) /. 0.5) in
    C.save ctx;
    C.set_text_align ctx "center";
    C.translate ctx ~x:(w /. 2.) ~y:120.;
    C.scale ctx ~x:(0.6 +. (p *. 0.4)) ~y:(0.6 +. (p *. 0.4));
    C.set_alpha ctx p;
    C.set_fill ctx Palette.win;
    C.set_shadow ctx ~color:"#0a3018" ~blur:16.;
    C.set_font ctx (font 30);
    C.fill_text ctx "YOU FOUND CAMEL O" ~x:0. ~y:0.;
    C.restore ctx;
    C.set_text_align ctx "left");
  if Float.( > ) t 2.6
  then (
    C.set_alpha ctx (Float.min 1. ((t -. 2.6) /. 0.6));
    C.set_text_align ctx "center";
    C.set_fill ctx "#ffe9c0";
    C.set_font ctx (font 11);
    C.fill_text ctx "REUNITED AT LAST" ~x:(w /. 2.) ~y:158.;
    C.set_alpha ctx 1.;
    C.set_text_align ctx "left")
;;

let draw ~ctx ~event ~t_seconds:t ~now_ms ~random_state ~support =
  match (event : Cutscene.Event.t) with
  | Banana_slip -> draw_banana_slip ctx ~t ~now_ms ~support
  | Jumpscare -> draw_jumpscare ctx ~t ~random_state
  | Finding_o -> draw_finding_o ctx ~t ~now_ms ~support
;;
