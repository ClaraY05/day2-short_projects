open! Core
open Bonsai_web

let style rules = Vdom.Attr.create "style" (String.concat ~sep:";" rules)

let page =
  style
    [ "min-height:100vh"
    ; "display:flex"
    ; "align-items:center"
    ; "justify-content:center"
    ; "background:radial-gradient(120% 120% at 50% 30%,#0a0a16 0%,#000 70%)"
    ; "font-family:'Press Start 2P',monospace"
    ; "padding:24px"
    ]
;;

let column = style [ "position:relative"; "width:720px" ]

let header_row =
  style
    [ "display:flex"
    ; "align-items:center"
    ; "justify-content:space-between"
    ; "padding:0 6px 10px"
    ; "color:#4a4f75"
    ; "font-size:9px"
    ; "letter-spacing:1px"
    ]
;;

let header_title = style [ [%string "color:%{Palette.beast}"] ]

let console =
  style
    [ "position:relative"
    ; "border:4px solid #1a1a2e"
    ; "border-radius:14px"
    ; "padding:10px"
    ; "background:#000"
    ; [%string
        "box-shadow:0 0 0 2px %{Palette.wall},0 18px 60px \
         rgba(217,122,30,.28),inset 0 0 40px rgba(0,0,0,.9)"]
    ]
;;

let scanlines =
  style
    [ "position:absolute"
    ; "inset:10px"
    ; "border-radius:6px"
    ; "pointer-events:none"
    ; "background:repeating-linear-gradient(0deg,rgba(0,0,0,0) \
       0px,rgba(0,0,0,0) 2px,rgba(0,0,0,.18) 3px,rgba(0,0,0,0) 4px)"
    ; "mix-blend-mode:multiply"
    ]
;;

let footer =
  style
    [ "text-align:center"
    ; "color:#2f3452"
    ; "font-size:8px"
    ; "letter-spacing:1px"
    ; "margin-top:12px"
    ]
;;

let hud_bar =
  style
    [ "position:absolute"
    ; "top:14px"
    ; "left:14px"
    ; "right:14px"
    ; "display:flex"
    ; "align-items:center"
    ; "justify-content:space-between"
    ; "gap:10px"
    ; "pointer-events:none"
    ]
;;

let hud_stats =
  style
    [ "display:flex"
    ; "gap:16px"
    ; [%string "color:%{Palette.hud_text}"]
    ; "font-size:9px"
    ]
;;

let hud_goal = style [ [%string "color:%{Palette.hud_accent_gold}"] ]
let hud_slips_value = style [ [%string "color:%{Palette.banana}"] ]
let hud_score_value = style [ [%string "color:%{Palette.score}"] ]

let hud_quit_button =
  style
    [ "pointer-events:auto"
    ; "font-family:inherit"
    ; "font-size:9px"
    ; [%string "color:%{Palette.beast}"]
    ; "background:rgba(10,10,22,.7)"
    ; [%string "border:2px solid %{Palette.beast}"]
    ; "border-radius:5px"
    ; "padding:7px 10px"
    ; "cursor:pointer"
    ]
;;

let caption_area =
  style
    [ "position:absolute"
    ; "left:16px"
    ; "right:16px"
    ; "bottom:16px"
    ; "pointer-events:none"
    ]
;;

let caption_tab =
  style
    [ "display:inline-block"
    ; "background:#0a0603"
    ; [%string "border:2px solid %{Palette.wall}"]
    ; "border-bottom:none"
    ; "border-radius:5px 5px 0 0"
    ; "padding:5px 13px"
    ; "transform:translateY(2px)"
    ]
;;

let caption_tab_text =
  style
    [ "color:#ff9d2f"
    ; "font-size:11px"
    ; "letter-spacing:1px"
    ; "text-shadow:1px 1px 0 #000"
    ]
;;

let caption_box =
  style
    [ "background:linear-gradient(180deg,rgba(12,7,3,.86),rgba(6,3,1,.94))"
    ; [%string "border:2px solid %{Palette.wall}"]
    ; "border-radius:0 7px 7px 7px"
    ; "padding:15px 17px 13px"
    ; "min-height:80px"
    ; "box-shadow:0 8px 30px rgba(0,0,0,.5)"
    ]
;;

let caption_text =
  style
    [ "color:#f3e6cf"
    ; "font-size:11px"
    ; "line-height:1.75"
    ; "text-shadow:1px 1px 0 #000"
    ]
;;

let caption_hint =
  style
    [ "color:#8a6a3a"
    ; "font-size:8px"
    ; "margin-top:13px"
    ; "letter-spacing:1px"
    ]
;;

(* The lobby's difficulty book: a small ledger pinned to the top-left of the
   console, keyboard-driven so it takes no pointer events. *)

let book_area =
  style
    [ "position:absolute"
    ; "top:16px"
    ; "left:16px"
    ; "width:210px"
    ; "pointer-events:none"
    ]
;;

let book_panel =
  style
    [ "background:linear-gradient(180deg,rgba(12,7,3,.9),rgba(6,3,1,.95))"
    ; [%string "border:2px solid %{Palette.wall}"]
    ; "border-radius:7px"
    ; "padding:12px 13px 11px"
    ; "box-shadow:0 8px 30px rgba(0,0,0,.5)"
    ]
;;

let book_title =
  style
    [ "color:#ff9d2f"
    ; "font-size:9px"
    ; "letter-spacing:1px"
    ; "text-shadow:1px 1px 0 #000"
    ; "margin-bottom:11px"
    ]
;;

let book_rows = style [ "display:flex"; "flex-direction:column"; "gap:7px" ]

let book_row ~is_selected =
  style
    [ "display:flex"
    ; "align-items:center"
    ; "gap:9px"
    ; "padding:5px 6px"
    ; "border-radius:4px"
    ; ("border-left:3px solid "
       ^ if is_selected then Palette.wall else "transparent")
    ; ("background:"
       ^ if is_selected then "rgba(217,122,30,.16)" else "transparent")
    ]
;;

let book_slot ~is_selected =
  style
    [ "flex:none"
    ; "width:16px"
    ; "text-align:center"
    ; "font-size:10px"
    ; ("color:" ^ if is_selected then Palette.banana else "#8a6a3a")
    ]
;;

let book_label ~is_selected =
  style
    [ "font-size:10px"
    ; "letter-spacing:1px"
    ; "text-shadow:1px 1px 0 #000"
    ; ("color:" ^ if is_selected then Palette.camel else "#8a6a3a")
    ]
;;

let book_hint =
  style
    [ "color:#8a6a3a"
    ; "font-size:8px"
    ; "letter-spacing:1px"
    ; "line-height:1.7"
    ; "margin-top:11px"
    ]
;;

let overlay ~backdrop =
  style
    [ "position:absolute"
    ; "inset:10px"
    ; "border-radius:6px"
    ; "display:flex"
    ; "flex-direction:column"
    ; "align-items:center"
    ; "justify-content:center"
    ; "text-align:center"
    ; backdrop
    ]
;;

let overlay_won =
  overlay
    ~backdrop:
      "background:radial-gradient(100% 90% at 50% 40%,rgba(20,30,20,.95) \
       0%,rgba(2,6,2,.98) 75%)"
;;

let overlay_lost =
  overlay
    ~backdrop:
      "background:radial-gradient(100% 90% at 50% 40%,rgba(60,0,14,.95) \
       0%,rgba(8,0,2,.98) 75%)"
;;

let won_title =
  style
    [ [%string "color:%{Palette.win}"]
    ; "font-size:34px"
    ; "letter-spacing:3px"
    ; [%string "text-shadow:0 0 18px %{Palette.win}"]
    ]
;;

let lost_title =
  style
    [ [%string "color:%{Palette.beast}"]
    ; "font-size:46px"
    ; "letter-spacing:4px"
    ; [%string "text-shadow:0 0 20px %{Palette.beast}"]
    ; "animation:slippulse 1.4s infinite"
    ]
;;

let won_stats =
  style
    [ [%string "color:%{Palette.hud_text}"]
    ; "font-size:10px"
    ; "margin-top:20px"
    ; "line-height:1.6"
    ]
;;

let lost_stats =
  style
    [ "color:#b0708a"
    ; "font-size:10px"
    ; "margin-top:20px"
    ; "line-height:1.6"
    ]
;;

let button_row = style [ "display:flex"; "gap:14px"; "margin-top:34px" ]

let primary_button ~fill =
  style
    [ "font-family:inherit"
    ; "font-size:12px"
    ; [%string "color:%{Palette.void}"]
    ; [%string "background:%{fill}"]
    ; "border:none"
    ; "border-radius:7px"
    ; "padding:14px 24px"
    ; "cursor:pointer"
    ; "letter-spacing:1px"
    ]
;;

let ghost_button =
  style
    [ "font-family:inherit"
    ; "font-size:12px"
    ; [%string "color:%{Palette.hud_text}"]
    ; "background:transparent"
    ; "border:2px solid #3a3f5f"
    ; "border-radius:7px"
    ; "padding:14px 24px"
    ; "cursor:pointer"
    ; "letter-spacing:1px"
    ]
;;
