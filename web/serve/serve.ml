(** A tiny static web server that launches the Camel O game.

    The game is a js_of_ocaml bundle plus [index.html]; the [web/serve/dune]
    file copies both next to this executable and makes building the launcher
    build the bundle, so [dune exec web/serve/serve.exe] compiles the game
    and serves it in one step. Everything visible is still built in OCaml
    (Bonsai); this only hands the browser the files. *)

open! Core
open Async

(* The launcher serves the directory it was built into, which holds the
   copied [index.html] and [main.bc.js]. *)
let root () = Filename.dirname Stdlib.Sys.executable_name

let content_type file =
  match snd (Filename.split_extension file) with
  | Some "html" -> "text/html; charset=utf-8"
  | Some "js" -> "text/javascript; charset=utf-8"
  | Some "css" -> "text/css; charset=utf-8"
  | Some "mp3" -> "audio/mpeg"
  | Some ("png" | "ico") -> "image/png"
  | Some _ | None -> "application/octet-stream"
;;

let handler ~root ~body:_ (_ : Socket.Address.Inet.t) request =
  let path = Uri.path (Cohttp.Request.uri request) in
  let relative =
    match String.lstrip path ~drop:(Char.equal '/') with
    | "" -> "index.html"
    | other -> other
  in
  (* Never climb out of the served directory. *)
  if String.is_substring relative ~substring:".."
  then Cohttp_async.Server.respond_string ~status:`Forbidden "forbidden\n"
  else (
    let file = root ^/ relative in
    match%bind Sys.file_exists file with
    | `Yes ->
      let headers =
        Cohttp.Header.init_with "content-type" (content_type file)
      in
      Cohttp_async.Server.respond_with_file ~headers file
    | `No | `Unknown ->
      Cohttp_async.Server.respond_string ~status:`Not_found "not found\n")
;;

let serve ~port () =
  let root = root () in
  let%bind (_ : (_, _) Cohttp_async.Server.t) =
    Cohttp_async.Server.create
      ~on_handler_error:`Raise
      (Tcp.Where_to_listen.of_port port)
      (handler ~root)
  in
  printf
    "Camel O is running \xe2\x80\x94 open http://localhost:%d/ in a browser\n\
     %!"
    port;
  printf
    "(map view at http://localhost:%d/map_view.html; serving %s; press \
     Ctrl-C to stop)\n\
     %!"
    port
    root;
  Deferred.never ()
;;

let command =
  Command.async
    ~summary:"Serve the Camel O web game over HTTP"
    (let%map_open.Command port =
       flag
         "-port"
         (optional_with_default 8080 int)
         ~doc:"PORT port to listen on (default 8080)"
     in
     fun () -> serve ~port ())
;;

let () = Command_unix.run command
