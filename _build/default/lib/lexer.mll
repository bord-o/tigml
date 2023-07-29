{
  open Parser

  exception Error of string

}

(* This rule looks for a single line, terminated with '\n' or eof.
   It returns a pair of an optional string (the line that was found)
   and a Boolean flag (false if eof was reached). *)
let digit = ['0'-'9']
let digits = digit+
let alpha = ['a'-'z''A'-'Z']
let alphas = alpha+
let ws    = [' ' '\t']
let nl    = ['\n']



rule token = parse
| ws+
    { token lexbuf }
| '\n'
    { END }

| '/'
    {print_endline "divide"; DIVIDE}

| eof
    (* Normal case: no data, eof. *)
    { raise (Error (Printf.sprintf "At offset %d: End of file encountered.\n" (Lexing.lexeme_start lexbuf))) }
| _
    { raise (Error (Printf.sprintf "At offset %d: unexpected character.\n" (Lexing.lexeme_start lexbuf))) }

