(** The Bonsai web frontend for {e Slip / Camel O}.

    {!App} is the page; everything else is its supporting cast. The rules
    live in [sandbox.engine], the screen flow in [sandbox.app]; this library
    only draws and listens. The [web/bin] executable compiles it all to
    JavaScript with js_of_ocaml. *)

(** The page: state machine, chrome, HUD and key handling. *)
module App = App

(** Float-friendly wrapper over the js_of_ocaml 2D canvas API. *)
module Canvas2d = Canvas2d

(** The three full-screen cutscenes, frame by frame. *)
module Cutscene_scene = Cutscene_scene

(** The canvas as a vdom widget; owns the requestAnimationFrame loop. *)
module Game_canvas = Game_canvas

(** The walkable desert-camp intro, painted. *)
module Lobby_scene = Lobby_scene

(** The torch-lit maze, painted. *)
module Maze_scene = Maze_scene

(** Camel O colors, shared by canvas and chrome. *)
module Palette = Palette

(** The pixel-art cast. *)
module Sprites = Sprites

(** Style tokens for the vdom chrome. *)
module Styles = Styles
