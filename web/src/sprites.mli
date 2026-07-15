(** The pixel-art cast, ported stroke for stroke from the Claude-design
    mockups. Every function draws around an [(x, y)] anchor on the current
    transform; [now_ms] drives idle bobbing so sprites never sit still.

    {!Maze_scene} draws them cell-sized, the cutscenes blow them up with
    [scale], e.g.
    [Sprites.trader ~ctx ~x ~y ~facing:East ~now_ms ~moving:true ~scale:2.4 ()]. *)

open! Core
open Sandbox_engine

(** The turbaned desert trader. [rotation] (radians) spins the whole sprite —
    the banana-slip cutscene's pratfall. The anchor is the trader's feet. *)
val trader
  :  ctx:Canvas2d.t
  -> x:float
  -> y:float
  -> facing:Direction.t
  -> now_ms:float
  -> moving:bool
  -> scale:float
  -> ?rotation:float
  -> unit
  -> unit

(** Camel O, glowing gold in the maze ([`In_maze]) or sandy and mirrored at
    dawn in the reunion cutscene ([`Reunion]). Anchored at the center of its
    body. *)
val camel
  :  ctx:Canvas2d.t
  -> x:float
  -> y:float
  -> now_ms:float
  -> style:[ `In_maze | `Reunion ]
  -> scale:float
  -> unit

(** The horned beast as seen prowling the maze, anchored mid-body;
    [cell_size] scales it like the mockup's [S]. *)
val beast
  :  ctx:Canvas2d.t
  -> x:float
  -> y:float
  -> cell_size:float
  -> color:string
  -> unit

(** A banana peel, slightly rotated like the mockup's. *)
val banana : ctx:Canvas2d.t -> x:float -> y:float -> scale:float -> unit

(** A score pellet. *)
val dot : ctx:Canvas2d.t -> x:float -> y:float -> unit

(** A pickup torch: stem, flame and bright tip. *)
val torch : ctx:Canvas2d.t -> x:float -> y:float -> unit

(** A pixel heart (the reunion cutscene), [size] pixels per lobe. *)
val heart : ctx:Canvas2d.t -> x:float -> y:float -> size:float -> unit

(** A four-pointed dizzy star (the pratfall). *)
val spark : ctx:Canvas2d.t -> x:float -> y:float -> color:string -> unit
