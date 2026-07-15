open! Core
open Sandbox_app

let%expect_test "no scenes are drawn yet: every event cuts straight through" =
  List.iter
    [ Cutscene.Event.Banana_slip
    ; Jumpscare { monster_name = "chaser" }
    ; Victory
    ]
    ~f:(fun event ->
      print_s
        [%message
          ""
            ~_:(event : Cutscene.Event.t)
            ~scene:(Cutscene.for_event event : Cutscene.t option)]);
  [%expect
    {|
    (Banana_slip (scene ()))
    ((Jumpscare (monster_name chaser)) (scene ()))
    (Victory (scene ()))
    |}]
;;

let%expect_test "a cutscene needs at least one frame" =
  Expect_test_helpers_core.require_does_raise (fun () ->
    Cutscene.create [] ~frame_duration:(Time_ns.Span.of_int_ms 100));
  [%expect {| "Cutscene.create: a cutscene needs at least one frame" |}]
;;

let%expect_test "frames and timing round-trip" =
  let scene =
    Cutscene.create
      [ "frame one"; "frame two" ]
      ~frame_duration:(Time_ns.Span.of_int_ms 80)
  in
  print_s
    [%message
      ""
        ~frames:(Cutscene.frames scene : string list)
        ~frame_duration:(Cutscene.frame_duration scene : Time_ns.Span.t)];
  [%expect {| ((frames ("frame one" "frame two")) (frame_duration 80ms)) |}]
;;
