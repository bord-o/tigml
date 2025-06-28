open Tigml


let show_exceptions = false

let test_program filename =
  try
    let infile = open_in filename in
    let file_content = really_input_string infile (in_channel_length infile) in
    let filebuf = Lexing.from_string file_content in
    let absyn = Parser.main Lexer.token filebuf in
    let ir = Semant.typecheckProg absyn in
    print_endline @@ Tree.show_exp ir;
    close_in infile
  with e ->
    print_endline @@ Printexc.to_string e

let () = 
    match Sys.argv |> Array.to_list with
    | [ _; f ] -> test_program f
    | _ -> failwith "USAGE: tigml [FILE]"
