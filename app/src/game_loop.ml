open! Core
open Sandbox_engine

let clear_screen = "\027[2J\027[H"
let hide_cursor = "\027[?25l"
let show_cursor = "\027[?25h"
let ctrl_c = '\003'

let action_of_key game key : Game.Action.t option =
  match Game.phase game, key with
  | Start_screen, ('\n' | '\r' | ' ') -> Some Start
  | Start_screen, _ -> None
  | Playing, 'w' -> Some Move_forward
  | Playing, 'a' -> Some Turn_left
  | Playing, 'd' -> Some Turn_right
  | Playing, 's' -> Some Turn_around
  | Playing, 'q' -> Some Quit
  | Playing, _ -> None
  | (Won | Lost), _ ->
    (* Any key dismisses the end screen. *)
    Some Quit
;;

let wants_to_leave game key =
  Char.equal key ctrl_c
  || (Game.Phase.equal (Game.phase game) Start_screen && Char.equal key 'q')
;;

let rec loop game =
  print_string clear_screen;
  print_string (Render.render game);
  Out_channel.flush stdout;
  match In_channel.input_char In_channel.stdin with
  | None -> ()
  | Some key ->
    if wants_to_leave game key
    then ()
    else (
      match action_of_key game key with
      | None -> loop game
      | Some action -> loop (Game.handle_action game action))
;;

(* Raw-ish mode: no line buffering, no echo, and no signal keys so that
   Ctrl-C flows through [loop] and the terminal is always restored. *)
let with_raw_terminal f =
  let fd = Core_unix.stdin in
  let original = Core_unix.Terminal_io.tcgetattr fd in
  let raw =
    { original with
      Core_unix.Terminal_io.c_icanon = false
    ; c_echo = false
    ; c_isig = false
    ; c_vmin = 1
    ; c_vtime = 0
    }
  in
  Core_unix.Terminal_io.tcsetattr raw fd ~mode:TCSANOW;
  Exn.protect ~f ~finally:(fun () ->
    Core_unix.Terminal_io.tcsetattr original fd ~mode:TCSANOW)
;;

let run () =
  if not (Core_unix.isatty Core_unix.stdin)
  then
    print_endline
      "Slip needs an interactive terminal; run it from a real TTY."
  else (
    let random_state = Random.State.make_self_init () in
    let game = Game.create ~random_state () in
    print_string hide_cursor;
    Exn.protect
      ~f:(fun () -> with_raw_terminal (fun () -> loop game))
      ~finally:(fun () ->
        print_string show_cursor;
        print_string clear_screen;
        Out_channel.flush stdout))
;;
