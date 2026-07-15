open! Core
open Sandbox_engine
open Sandbox_app

let print_lobby lobby =
  print_s
    [%message
      ""
        ~x:(Lobby.x lobby : float)
        ~facing:(Lobby.facing lobby : Direction.t)
        ~is_walking:(Lobby.is_walking lobby : bool)
        ~zone:(Lobby.zone lobby : int)
        ~can_enter:(Lobby.can_enter lobby : bool)]
;;

let%expect_test "the trader starts by the camp, facing the dunes" =
  print_lobby (Lobby.create ());
  [%expect
    {| ((x 300) (facing East) (is_walking false) (zone 0) (can_enter false)) |}]
;;

let%expect_test "walking east crosses the four dialogue zones and unlocks \
                 the entrance"
  =
  let lobby = ref (Lobby.create ()) in
  let zone = ref (-1) in
  (* 185 px/s for 12 s crosses the whole 1900 px camp. *)
  List.iter (List.range 0 120) ~f:(fun _ ->
    lobby := Lobby.step !lobby ~dt:0.1 ~held:(Some East);
    if Lobby.zone !lobby <> !zone
    then (
      zone := Lobby.zone !lobby;
      print_s
        [%message
          ""
            ~zone:(!zone : int)
            ~x:(Float.round_nearest (Lobby.x !lobby) : float)
            ~dialogue:(String.prefix (Lobby.dialogue !lobby) 24 : string)]));
  print_s [%message "" ~can_enter:(Lobby.can_enter !lobby : bool)];
  [%expect
    {|
    ((zone 0) (x 319) (dialogue "Camp's gone quiet withou"))
    ((zone 1) (x 522) (dialogue "...and of course a banan"))
    ((zone 2) (x 1151) (dialogue "One wrong step on those "))
    ((zone 3) (x 1577) (dialogue "Your tracks lead straigh"))
    (can_enter true)
    |}]
;;

let%expect_test "the trader stops at the campfire and the gap, and standing \
                 still faces the last direction walked"
  =
  let lobby = Lobby.step (Lobby.create ()) ~dt:60. ~held:(Some West) in
  print_lobby lobby;
  let lobby = Lobby.step lobby ~dt:0.1 ~held:None in
  print_lobby lobby;
  let lobby = Lobby.step lobby ~dt:60. ~held:(Some East) in
  print_lobby lobby;
  [%expect
    {|
    ((x 272) (facing West) (is_walking true) (zone 0) (can_enter false))
    ((x 272) (facing West) (is_walking false) (zone 0) (can_enter false))
    ((x 1780) (facing East) (is_walking true) (zone 3) (can_enter true))
    |}]
;;

let%expect_test "vertical keys do not scroll the camp" =
  let before = Lobby.create () in
  let after = Lobby.step before ~dt:1. ~held:(Some North) in
  print_s
    [%message
      "" ~moved:(Float.( <> ) (Lobby.x before) (Lobby.x after) : bool)];
  [%expect {| (moved false) |}]
;;
