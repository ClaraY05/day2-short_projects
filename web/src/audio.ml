open! Core
open Js_of_ocaml

module Music = struct
  type t =
    | Lobby
    | Gameplay
  [@@deriving equal]

  let file = function
    | Lobby -> "lobby_music.mp3"
    | Gameplay -> "gameplay_music.mp3"
  ;;

  let volume = 0.35
end

module Effect = struct
  type t =
    | Item_pickup
    | Game_over
    | Banana_slip

  let file = function
    | Item_pickup -> "itempickup_effect.mp3"
    | Game_over -> "gameover_effect.mp3"
    | Banana_slip -> "banana_effect.mp3"
  ;;

  (* Pickups fire constantly, so they sit at half the volume of the rare,
     dramatic cues. *)
  let volume = function
    | Item_pickup -> 0.1
    | Game_over | Banana_slip -> 0.6
  ;;
end

let make_element ~file ~loop ~volume =
  let element = Dom_html.createAudio Dom_html.document in
  element##.src := Js.string file;
  element##.loop := Js.bool loop;
  element##.volume := Js.number_of_float volume;
  element##.preload := Js.string "auto";
  element
;;

(* One element per clip, built on first use. Music loops; effects are
   one-shots restarted from the top so rapid pickups still sound. *)
let music_element =
  let lobby =
    lazy
      (make_element ~file:(Music.file Lobby) ~loop:true ~volume:Music.volume)
  in
  let gameplay =
    lazy
      (make_element
         ~file:(Music.file Gameplay)
         ~loop:true
         ~volume:Music.volume)
  in
  function
  | Music.Lobby -> Lazy.force lobby
  | Gameplay -> Lazy.force gameplay
;;

let effect_element =
  let pickup =
    lazy
      (make_element
         ~file:(Effect.file Item_pickup)
         ~loop:false
         ~volume:(Effect.volume Item_pickup))
  in
  let game_over =
    lazy
      (make_element
         ~file:(Effect.file Game_over)
         ~loop:false
         ~volume:(Effect.volume Game_over))
  in
  let banana =
    lazy
      (make_element
         ~file:(Effect.file Banana_slip)
         ~loop:false
         ~volume:(Effect.volume Banana_slip))
  in
  function
  | Effect.Item_pickup -> Lazy.force pickup
  | Game_over -> Lazy.force game_over
  | Banana_slip -> Lazy.force banana
;;

(* Autoplay stays blocked until a gesture, so hold the desired track and only
   touch the elements once [unlocked]. *)
let unlocked = ref false
let desired : Music.t option ref = ref None
let current : Music.t option ref = ref None

(* play () can reject its promise (e.g. a race with a pause); the binding
   types it [unit] and drops the promise, so guard only against a synchronous
   throw. *)
let start element =
  try element##play with
  | _ -> ()
;;

let apply_desired () =
  match !desired, !current with
  | Some track, Some playing when Music.equal track playing -> ()
  | Some track, _ ->
    Option.iter !current ~f:(fun playing -> (music_element playing)##pause);
    let element = music_element track in
    element##.currentTime := Js.number_of_float 0.;
    start element;
    current := Some track
  | None, _ ->
    Option.iter !current ~f:(fun playing -> (music_element playing)##pause);
    current := None
;;

let play_music track =
  desired := Some track;
  if !unlocked then apply_desired ()
;;

let stop_music () =
  desired := None;
  if !unlocked then apply_desired ()
;;

let play_effect effect =
  if !unlocked
  then (
    let element = effect_element effect in
    element##.currentTime := Js.number_of_float 0.;
    start element)
;;

let unlock () =
  if not !unlocked
  then (
    unlocked := true;
    apply_desired ())
;;
