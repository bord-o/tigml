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
    {next_line lexbuf; token lexbuf }
    
| "if"
    {pp "IF"; IF}
| "var"
    {pp "VAR"; VAR}
| "function"
    {pp "FUNCTION"; FUNCTION}

(*string time*)
| '"'
    {string_active := true; read_string (Buffer.create 17) lexbuf}

| "/*"
    {comment_active := true; comment_depth := !comment_depth + 1; comment lexbuf}

| "break"
    {pp "break";BREAK}
| "of"
    {pp "OF"; OF}
| "end"
    {pp "END"; END}
| "in"
    {pp "IN"; IN}
| "nil"
    {pp "NIL"; NIL}
| "let"
    {pp "LET"; LET}
| "do"
    {pp "DO"; DO}
| "to"
    {pp "TO"; TO}
| "for"
    {pp "FOR"; FOR}
| "while"
    {pp "WHILE"; WHILE}
| "else"
    {pp "ELSE"; ELSE}
| "then"
    {pp "THEN"; THEN}
| "array"
    {pp "ARRAY"; ARRAY}

| "type"
    {pp "TYPE"; TYPE}

| alpha(alpha | digit | "_")* as id
    {pp @@ "ID: " ^ id ; ID id}

| digits as num
    {pp @@ "INT: " ^ num; INT (int_of_string num)}

| ":="
    {pp "ASSIGN"; ASSIGN}

| ","
    {pp "COMMA"; COMMA}

| "|"
    {pp "OR"; OR}

| "&"
    {pp "AND"; AND}

| ">="
    {pp "GE"; GE}

| ">"
    {pp "GT"; GT}

| "<="
    {pp "LE"; LE}

| "<"
    {pp "LT"; LT}

| "<>"
    {pp "NEQ"; NEQ}

| "="
    {pp "EQ"; EQ}

| '*'
    {pp "TIMES"; TIMES}

| '/'
    {print_endline "DIVIDE"; DIVIDE}

| "-"
    {pp "MINUS"; MINUS}

| "+"
    {pp "PLUS"; PLUS}

| "."
    {pp "DOT"; DOT}

| "["
    {pp "LBRACK"; LBRACK}

| "]"
    {pp "RBRACK"; RBRACK}

| "{"
    {pp "LBRACE"; LBRACE}

| "}"
    {pp "RBRACE"; RBRACE}

| "("
    {pp "LPAREN"; LPAREN}

| ")"
    {pp "RPAREN"; RPAREN}

| ":"
    {pp "COLON"; COLON}

| ";"
    {pp "SEMICOLON"; SEMICOLON}

| eof
    (* Normal case: no data, eof. *)
    {pp "EOF"; EOF}
| _
    { raise (Error (locate lexbuf; Printf.sprintf "At offset %d: unexpected character.\n" (Lexing.lexeme_start lexbuf) )) }

and read_string buf = parse
  | '"'       { (pp @@ Printf.sprintf "STRING: %s" (Buffer.contents buf)); STRING (Buffer.contents buf) }
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
    {comment_depth := !comment_depth - 1;
     if !comment_depth = 0 then (comment_active := false;token lexbuf )
     else (comment lexbuf)}
| nl
    {next_line lexbuf; comment lexbuf}
| _
    {if !comment_active then comment lexbuf else token lexbuf}