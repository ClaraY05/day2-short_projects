open! Core

module Event = struct
  type t =
    | Banana_slip
    | Jumpscare of { monster_name : string }
    | Victory
  [@@deriving sexp_of, compare, equal]
end

type t =
  { frames : string list
  ; frame_duration : Time_ns.Span.t
  }
[@@deriving sexp_of, fields ~getters]

let create frames ~frame_duration =
  match frames with
  | [] ->
    raise_s [%message "Cutscene.create: a cutscene needs at least one frame"]
  | _ :: _ -> { frames; frame_duration }
;;

let for_event (event : Event.t) =
  (* The art is not drawn yet; every event cuts straight to the next screen.
     Frames go here, next to their event. *)
  match event with
  | Banana_slip -> None
  | Jumpscare { monster_name = _ } -> None
  | Victory -> None
;;
