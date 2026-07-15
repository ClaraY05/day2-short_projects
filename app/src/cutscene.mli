(** The three full-screen cutscenes and how long each runs.

    The art itself is drawn frame by frame by the web painter; what lives
    here is the pure part every layer agrees on — which cutscene plays for
    which dramatic moment and its length, so {!Flow} knows what state follows
    and tests need no clock. Durations are the loop lengths of the
    Claude-design mockups.

    {[
      Cutscene.duration_seconds Banana_slip = 4.8
    ]} *)

open! Core

module Event : sig
  (** The moments worth interrupting the game for. [Banana_slip] plays before
      waking up in the reshuffled maze, [Jumpscare] before the lose screen,
      [Finding_o] before the win screen. *)
  type t =
    | Banana_slip
    | Jumpscare
    | Finding_o
  [@@deriving sexp_of, compare, equal, enumerate]
end

val duration_seconds : Event.t -> float
