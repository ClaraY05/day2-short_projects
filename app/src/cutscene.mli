(** Full-screen cutscene animations, one per dramatic moment.

    A cutscene is a short, timed sequence of full-screen text frames played
    between two states of the game: slipping on a banana will play one before
    the player wakes up in the reshuffled maze, and getting caught will play
    a jumpscare animation before the lose screen. {!Game_loop} is the
    intended driver — clear the terminal, print each frame, wait
    {!frame_duration}, ignore input until the scene ends.

    Only the plumbing exists so far: nobody has drawn the art, so
    {!for_event} is [None] for every event and the game cuts straight to its
    next screen. To bring a scene to life, build its frames (ASCII art and,
    later, sound cues belong under [assets/]) and return them from
    {!for_event}:

    {[
      let slip =
        Cutscene.create
          [ frame_1; frame_2; frame_3 ]
          ~frame_duration:(Time_ns.Span.of_int_ms 120)
      ;;
    ]} *)

open! Core

module Event : sig
  (** The moments worth interrupting the game for. *)
  type t =
    | Banana_slip (** stepped on a banana; plays before waking up *)
    | Jumpscare of { monster_name : string }
    (** caught; plays before the lose screen *)
    | Victory (** the key turns; plays before the win screen *)
  [@@deriving sexp_of, compare, equal]
end

type t [@@deriving sexp_of]

(** [create frames ~frame_duration] is a scene that shows each frame in
    order, holding it on screen for [frame_duration]. Raises if [frames] is
    empty. *)
val create : string list -> frame_duration:Time_ns.Span.t -> t

val frames : t -> string list
val frame_duration : t -> Time_ns.Span.t

(** The scene to play when [event] happens, or [None] to cut straight to the
    next screen. All [None] until the art gets drawn. *)
val for_event : Event.t -> t option
