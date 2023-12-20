open Tigml
open Semant

let process buf =
  try
    (* Run the parser on this line of input. *)
    let absyn = Parser.main Lexer.token buf in
    Printf.printf "%s\n\n" @@ Absyn.show_exp absyn;
    Semant.transProg absyn
  with
  (*
    ignore (Lexer.token buf);
    process buf
    *)
  | Parser.Error -> raise Parser.Error
  | Lexer.Error msg -> print_endline msg

let buf_of_file program =
  let infile = open_in program in
  let file_content = really_input_string infile (in_channel_length infile) in
  close_in infile;

  Lexing.from_string file_content

let run_prog prog =
  let filebuf = buf_of_file prog in
  print_endline @@ "PROCESSING FILE: " ^ prog;
  process filebuf

let () =
  (* let infile = open_in "/home/bordo/tigml/test/calc.calc" in*)
  let open Printf in
  let progs =
    [
      "./test/merge.tig";
      (*
      "/home/bordo/tigml/test/test1.tig";
      "/home/bordo/tigml/test/test1.tig";
      "/home/bordo/tigml/test/test2.tig";
      "/home/bordo/tigml/test/test3.tig";
      "/home/bordo/tigml/test/test4.tig";
      "/home/bordo/tigml/test/test5.tig";
      "/home/bordo/tigml/test/test6.tig";
      "/home/bordo/tigml/test/test7.tig";
      "/home/bordo/tigml/test/test8.tig";
      "/home/bordo/tigml/test/test9.tig";
      "/home/bordo/tigml/test/test10.tig";
      "/home/bordo/tigml/test/test11.tig";
      "/home/bordo/tigml/test/test12.tig";
      "/home/bordo/tigml/test/test13.tig";
      "/home/bordo/tigml/test/test14.tig";
      "/home/bordo/tigml/test/test15.tig";
      "/home/bordo/tigml/test/test16.tig";
      "/home/bordo/tigml/test/test17.tig";
      "/home/bordo/tigml/test/test18.tig";
      "/home/bordo/tigml/test/test18.tig";
      "/home/bordo/tigml/test/test19.tig";
      "/home/bordo/tigml/test/test20.tig";
      "/home/bordo/tigml/test/test21.tig";
      "/home/bordo/tigml/test/test22.tig";
      "/home/bordo/tigml/test/test23.tig";
      "/home/bordo/tigml/test/test24.tig";
      "/home/bordo/tigml/test/test25.tig";
      "/home/bordo/tigml/test/test26.tig";
      "/home/bordo/tigml/test/test27.tig";
      "/home/bordo/tigml/test/test28.tig";
      "/home/bordo/tigml/test/test29.tig";
      "/home/bordo/tigml/test/test30.tig";
      "/home/bordo/tigml/test/test31.tig";
      "/home/bordo/tigml/test/test32.tig";
      "/home/bordo/tigml/test/test33.tig";
      "/home/bordo/tigml/test/test34.tig";
      "/home/bordo/tigml/test/test35.tig";
      "/home/bordo/tigml/test/test36.tig";
      "/home/bordo/tigml/test/test37.tig";
      "/home/bordo/tigml/test/test38.tig";
      "/home/bordo/tigml/test/test39.tig";
      "/home/bordo/tigml/test/test40.tig";
      "/home/bordo/tigml/test/test41.tig";
      "/home/bordo/tigml/test/test42.tig";
      "/home/bordo/tigml/test/test43.tig";
      "/home/bordo/tigml/test/test44.tig";
      "/home/bordo/tigml/test/test45.tig";
      "/home/bordo/tigml/test/test46.tig";
      "/home/bordo/tigml/test/test47.tig";
      "/home/bordo/tigml/test/test48.tig";
      (* "/home/bordo/tigml/test/test49.tig";  this is supposed to syntax error*)
      "/home/bordo/tigml/test/merge.tig";
      "/home/bordo/tigml/test/queens.tig";
      "/home/bordo/tigml/test/ast1.tig";
      "/home/bordo/tigml/test/ast2.tig";
      "/home/bordo/tigml/test/ast3.tig";
      "/home/bordo/tigml/test/ast4.tig";
      "/home/bordo/tigml/test/ast5.tig";
    *)
    ]
  in

  List.iter run_prog progs
