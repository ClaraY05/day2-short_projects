(** The pure application layer for {e Slip / Camel O}: everything the web
    frontend needs decided that does not touch the DOM.

    {!Flow} strings the {!Sandbox_engine.Game} together with the lobby, the
    cutscenes and the end screens; the remaining modules are the pure data
    each screen runs on. Rendering, the clock and the keyboard live in the
    [sandbox.web] library. *)

(** Which keys mean what. *)
module Controls = Controls

(** Cutscene identities and durations. *)
module Cutscene = Cutscene

(** Easy / normal / nightmare presets. *)
module Difficulty = Difficulty

(** Lobby, playing, cutscene, won, lost — and how they chain. *)
module Flow = Flow

(** The walkable desert-camp intro. *)
module Lobby = Lobby
