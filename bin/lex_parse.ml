open Tigml
open Tigml.Syntax

let rec process (buf) =
  try
    (* Run the parser on this line of input. *)
    (*ignore (Parser.main Lexer.token buf); process buf*)
    ignore (Lexer.token buf); process buf
    
  with
  (*
  | Lexer.Error msg ->
      Printf.fprintf stderr "%s%!" msg
  *)
  | Lexer.Error msg ->
    print_endline msg

let () =
  (* let infile = open_in "/home/bordo/tigml/test/calc.calc" in*) 
  let open Printf in
  let dirs = Sys.readdir "/home/bordo/tigml/test/" 
    |> Array.to_list 
    |> List.filter (String.ends_with ~suffix:".tig" ) 
    |> List.map (fun name -> "/home/bordo/tigml/test/" ^ name) in

  let _progs = [
      "/home/bordo/tigml/test/test1.tig";
      "/home/bordo/tigml/test/test2.tig";
      "/home/bordo/tigml/test/test3.tig";
      "/home/bordo/tigml/test/test4.tig";
    ] in
  List.iter (fun program -> 

    printf "Lexing program %s\n" program;
    let infile = open_in program in
    let linebuf = Lexing.from_channel infile in
    process linebuf;
    printf "\n"
    ) dirs

