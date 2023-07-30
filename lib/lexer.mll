{
  open Parser
  open Lexing

  exception Error of string
  let debug = true
  let pp = if debug then print_endline else (fun _ -> ())

  let comment_depth = ref 0
  let comment_active = ref false
  let string_active = ref false

     let next_line lexbuf =
        let pos = lexbuf.lex_curr_p in
        lexbuf.lex_curr_p <-
          { pos with pos_bol = lexbuf.lex_curr_pos;
                    pos_lnum = pos.pos_lnum + 1}
    let locate b =
      let pos = b.lex_curr_p
      in Printf.printf "Line: %i, pos: %i\n" pos.pos_lnum  pos.pos_bol
}

(* This rule looks for a single line, terminated with '\n' or eof.
   It returns a pair of an optional string (the line that was found)
   and a Boolean flag (false if eof was reached). *)
let digit = ['0'-'9']
let digits = digit+
let alpha = ['a'-'z''A'-'Z']
let alphas = alpha+
let ws    = [' ' '\t']
let nl = "\r\n" | '\n' | '\r'


rule token = parse
| ws+
    { token lexbuf }

| nl
    {pp "newline"; next_line lexbuf; token lexbuf }
    
| "if"
    {pp "if"; IF}
| "var"
    {pp "var"; VAR}
| "function"
    {pp "function"; FUNCTION}

(*string time*)
| '"'
    {pp "string start"; string_active := true; read_string (Buffer.create 17) lexbuf}

| "/*"
    {pp "starting comment"; comment_active := true; comment_depth := !comment_depth + 1; comment lexbuf}

| "break"
    {pp "break";BREAK}
| "of"
    {pp "of"; OF}
| "end"
    {pp "end"; END}
| "in"
    {pp "in"; IN}
| "nil"
    {pp "nil"; NIL}
| "let"
    {pp "let"; LET}
| "do"
    {pp "do"; DO}
| "to"
    {pp "to"; TO}
| "for"
    {pp "for"; FOR}
| "while"
    {pp "while"; WHILE}
| "else"
    {pp "else"; ELSE}
| "then"
    {pp "then"; THEN}
| "array"
    {pp "array"; ARRAY}

| "type"
    {pp "type"; TYPE}

| alpha(alpha | digit | "_")* as id
    {pp "id"; ID id}

| digits as num
    {pp "int"; INT (int_of_string num)}

| ":="
    {pp ":="; ASSIGN}

| ","
    {pp ","; COMMA}

| "|"
    {pp "|"; OR}

| "&"
    {pp "&"; AND}

| ">="
    {pp ">="; GE}

| ">"
    {pp ">"; GT}

| "<="
    {pp "<="; LE}

| "<"
    {pp "<"; LT}

| "<>"
    {pp "<>"; NEQ}

| "="
    {pp "="; EQ}

| '*'
    {pp "times"; TIMES}

| '/'
    {print_endline "divide"; DIVIDE}

| "-"
    {pp "-"; MINUS}

| "+"
    {pp "+"; PLUS}

| "."
    {pp "."; DOT}

| "["
    {pp "["; LBRACK}

| "]"
    {pp "]"; RBRACK}

| "{"
    {pp "{"; LBRACE}

| "}"
    {pp "}"; RBRACE}

| "("
    {pp "("; LPAREN}

| ")"
    {pp ")"; RPAREN}

| ":"
    {pp ":"; COLON}

| ";"
    {pp ";"; SEMICOLON}

| eof
    (* Normal case: no data, eof. *)
    { raise (Error (locate lexbuf; Printf.sprintf "At offset %d: End of file encountered.\n" (Lexing.lexeme_start lexbuf))) }
| _
    { raise (Error (locate lexbuf; Printf.sprintf "At offset %d: unexpected character.\n" (Lexing.lexeme_start lexbuf) )) }

and read_string buf = parse
  | '"'       { (pp @@ Printf.sprintf "string: %s" (Buffer.contents buf)); STRING (Buffer.contents buf) }
  | '\\' '/'  { Buffer.add_char buf '/'; read_string buf lexbuf }
  | '\\' '\\' { Buffer.add_char buf '\\'; read_string buf lexbuf }
  | '\\' 'b'  { Buffer.add_char buf '\b'; read_string buf lexbuf }
  | '\\' 'f'  { Buffer.add_char buf '\012'; read_string buf lexbuf }
  | '\\' 'n'  { Buffer.add_char buf '\n'; read_string buf lexbuf }
  | '\\' 'r'  { Buffer.add_char buf '\r'; read_string buf lexbuf }
  | '\\' 't'  { Buffer.add_char buf '\t'; read_string buf lexbuf }
  | [^ '"' '\\']+
    { Buffer.add_string buf (Lexing.lexeme lexbuf);
      read_string buf lexbuf
    }
  | _ { raise (Error ("Illegal string character: " ^ Lexing.lexeme lexbuf)) }
  | eof { raise (Error ("String is not terminated")) }

and comment = parse

| "*/"
    {pp "ending current comment";
     comment_depth := !comment_depth - 1;
     if !comment_depth = 0 then (comment_active := false;token lexbuf )
     else (comment lexbuf)}
| nl
    {pp "comment newline"; next_line lexbuf; comment lexbuf}
| _
    {if !comment_active then comment lexbuf else token lexbuf}