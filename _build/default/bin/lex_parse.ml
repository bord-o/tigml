open Tigml
open Tigml.Syntax

let rec process (buf) =
  try
    (* Run the parser on this line of input. *)
    (*ignore (Parser.main Lexer.token buf); process buf*)
    ignore (Lexer.token buf); process buf
    
  with
  | Lexer.Error msg ->
      Printf.fprintf stderr "%s%!" msg
  | Parser.Error ->
      Printf.fprintf stderr "At offset %d: syntax error.\n%!" (Lexing.lexeme_start buf)


let () =
  (* let infile = open_in "/home/bordo/tigml/test/calc.calc" in*) 
  let infile = open_in "/home/bordo/tigml/test/test1.tig" in
  let linebuf = Lexing.from_channel infile in
  process linebuf

