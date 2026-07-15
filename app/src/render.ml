open! Core
open Sandbox_engine

let escape = "\027"
let bell = "\007"

let color ~ansi code text =
  if ansi then [%string "%{escape}[%{code}m%{text}%{escape}[0m"] else text
;;

let tile_glyph ~ansi (tile : Viewport.Tile.t option) =
  match tile with
  | None -> "  "
  | Some Player -> color ~ansi "1;96" "^ "
  | Some Wall -> color ~ansi "90" "##"
  | Some Floor -> color ~ansi "2" ". "
  | Some Banana -> color ~ansi "93" "b "
  | Some Key -> color ~ansi "1;33" "K "
  | Some Monster -> color ~ansi "1;91" "M "
;;

(* In the map view the world is not rotated, so the player's glyph carries
   the direction they face instead of always pointing up. *)
let player_glyph ~ansi (facing : Direction.t) =
  let arrow =
    match facing with
    | North -> "^ "
    | South -> "v "
    | East -> "> "
    | West -> "< "
  in
  color ~ansi "1;96" arrow
;;

let strip_trailing_spaces text =
  String.split_lines text
  |> List.map ~f:String.rstrip
  |> String.concat ~sep:"\n"
;;

let start_screen ~ansi =
  let title = color ~ansi "1;95" "S  L  I  P" in
  [%string
    {|
            %{title}

         a banana horror maze

   Somewhere in the dark there is a key.
   Something in the dark is hunting you.
   Step on a banana and you slip, wake,
   and the walls will have moved.

     [enter] descend        [q] quit
|}]
;;

let playing_screen ~ansi game =
  let view =
    Viewport.view
      ~maze:(Game.maze_exn game)
      ~player:(Game.player_exn game)
      ~facing:(Game.facing_exn game)
      ~monster:(Some (Monster.position (Game.monster_exn game)))
      ~radius:(Game.light_radius game)
  in
  let grid =
    Array.to_list view
    |> List.map ~f:(fun row ->
      "   "
      ^ (Array.to_list row |> List.map ~f:(tile_glyph ~ansi) |> String.concat))
    |> String.concat ~sep:"\n"
  in
  let bananas = Game.bananas_remaining_exn game in
  let header =
    color ~ansi "2" [%string "bananas underfoot: %{bananas#Int}"]
  in
  let footer =
    color
      ~ansi
      "2"
      "[w] forward   [a]/[d] turn   [s] about-face   [q] give up"
  in
  [%string {|
   %{header}

%{grid}

   %{footer}
|}]
;;

let map_screen ~ansi game =
  let player = Game.player_exn game in
  let facing = Game.facing_exn game in
  let view =
    Viewport.full_map
      ~maze:(Game.maze_exn game)
      ~player
      ~monster:(Some (Monster.position (Game.monster_exn game)))
  in
  let grid =
    Array.to_list view
    |> List.mapi ~f:(fun row cells ->
      "   "
      ^ (Array.to_list cells
         |> List.mapi ~f:(fun col tile ->
           if row = player.Position.row && col = player.Position.col
           then player_glyph ~ansi facing
           else tile_glyph ~ansi tile)
         |> String.concat))
    |> String.concat ~sep:"\n"
  in
  let bananas = Game.bananas_remaining_exn game in
  let header =
    color ~ansi "2" [%string "map view — bananas underfoot: %{bananas#Int}"]
  in
  let footer =
    color
      ~ansi
      "2"
      "[w] forward   [a]/[d] turn   [s] about-face   [q] give up"
  in
  [%string {|
   %{header}

%{grid}

   %{footer}
|}]
;;

let won_screen ~ansi =
  let title = color ~ansi "1;92" "THE KEY TURNS." in
  [%string
    {|
        %{title}

   You are out. The maze forgets you.

        [any key] start screen
|}]
;;

let lost_screen ~ansi game =
  let face =
    {|
        .-------------------------.
       /      __         __       \
      |      /  \       /  \       |
      |      \__/       \__/       |
      |                            |
      |    \/\/\/\/\/\/\/\/\/\/    |
       \                          /
        '------------------------'
|}
  in
  let monster =
    match Game.monster_name game with Some name -> name | None -> "dark"
  in
  let scare = color ~ansi "1;91" face in
  let caption =
    color ~ansi "1;91" [%string "IT HAS YOU. (caught by the %{monster})"]
  in
  let ring = if ansi then bell else "" in
  [%string
    {|%{ring}%{scare}
        %{caption}

        [any key] start screen
|}]
;;

let render ?(ansi = true) game =
  (match Game.phase game with
   | Start_screen -> start_screen ~ansi
   | Playing -> playing_screen ~ansi game
   | Won -> won_screen ~ansi
   | Lost -> lost_screen ~ansi game)
  |> strip_trailing_spaces
;;

let render_map ?(ansi = true) game =
  (match Game.phase game with
   | Start_screen -> start_screen ~ansi
   | Playing -> map_screen ~ansi game
   | Won -> won_screen ~ansi
   | Lost -> lost_screen ~ansi game)
  |> strip_trailing_spaces
;;
