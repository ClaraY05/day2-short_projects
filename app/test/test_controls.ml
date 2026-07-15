open! Core
open Sandbox_app

let%expect_test "every binding, and a decoy" =
  List.iter
    [ "w"
    ; "ArrowUp"
    ; "s"
    ; "ArrowDown"
    ; "a"
    ; "ArrowLeft"
    ; "d"
    ; "ArrowRight"
    ; "Enter"
    ; " "
    ; "q"
    ]
    ~f:(fun key ->
      print_s
        [%message
          key ~_:(Controls.intent_of_key key : Controls.intent option)]);
  [%expect
    {|
    (w ((Move North)))
    (ArrowUp ((Move North)))
    (s ((Move South)))
    (ArrowDown ((Move South)))
    (a ((Move West)))
    (ArrowLeft ((Move West)))
    (d ((Move East)))
    (ArrowRight ((Move East)))
    (Enter (Confirm))
    (" " (Confirm))
    (q ())
    |}]
;;

let%expect_test "cutscene durations match the design mockups" =
  List.iter Sandbox_app.Cutscene.Event.all ~f:(fun event ->
    print_s
      [%message
        ""
          ~_:(event : Cutscene.Event.t)
          ~seconds:(Cutscene.duration_seconds event : float)]);
  [%expect
    {|
    (Banana_slip (seconds 4.8))
    (Jumpscare (seconds 3.6))
    (Finding_o (seconds 5))
    |}]
;;
