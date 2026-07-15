open! Core

module Event = struct
  type t =
    | Banana_slip
    | Jumpscare
    | Finding_o
  [@@deriving sexp_of, compare, equal, enumerate]
end

let duration_seconds : Event.t -> float = function
  | Banana_slip -> 4.8
  | Jumpscare -> 3.6
  | Finding_o -> 5.0
;;
