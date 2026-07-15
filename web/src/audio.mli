(** Sound for the Camel O web game: two looping music beds and three one-shot
    effects, played through HTML5 [<audio>] elements.

    {!Game_canvas} drives this from its animation-frame loop — it swaps the
    music when the screen changes ({!Music.Lobby} in the camp,
    {!Music.Gameplay} through the dunes and every cutscene) and fires an
    {!Effect} on the moments the flow surfaces: a dot or torch picked up, the
    monster's pounce, a banana underfoot.

    The audio files sit next to the compiled bundle (see [web/serve/dune] and
    [web/bin/dune], which copy them out of [assets/]), so the elements load
    them by bare relative name.

    Browsers refuse to start audio before the player interacts with the page,
    so nothing actually sounds until {!unlock} runs from a key handler; the
    desired track is remembered and started then.

    {[
      Audio.play_music Lobby;
      (* remembered; starts once unlocked *)
      Audio.unlock ();
      (* call from the first keydown *)
      Audio.play_effect Item_pickup
    ]} *)

open! Core

module Music : sig
  (** The two looping background beds. *)
  type t =
    | Lobby
    | Gameplay
  [@@deriving equal]
end

module Effect : sig
  (** The one-shot cues, one per uploaded [*_effect.mp3]. *)
  type t =
    | Item_pickup
    | Game_over
    | Banana_slip
end

(** Switch the looping background track. Idempotent — asking for the track
    already playing does nothing — so it is safe to call every frame. Before
    {!unlock} it only records the request. *)
val play_music : Music.t -> unit

(** Silence the background music (nothing plays until the next
    {!play_music}). *)
val stop_music : unit -> unit

(** Fire a one-shot effect from its start, cutting off any previous play of
    the same effect. A no-op until {!unlock}. *)
val play_effect : Effect.t -> unit

(** Grant playback on the first user gesture and start whatever {!play_music}
    last asked for. Call it from a key handler; calls after the first are
    cheap no-ops. *)
val unlock : unit -> unit
