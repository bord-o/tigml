open Tigml
open Tigml.Syntax
let process buf =
  try
    (* Run the parser on this line of input. *)
    ignore (Parser.main Lexer.token buf); 
    (*
    ignore (Lexer.token buf);
    process buf
    *)
  with
  | Parser.Error ->
      raise Parser.Error

  | Lexer.Error msg ->
    print_endline msg

let () =
  (* let infile = open_in "/home/bordo/tigml/test/calc.calc" in*)
  let open Printf in
  let _dirs =
    Sys.readdir "/home/bordo/tigml/test/"
    |> Array.to_list
    |> List.filter (String.ends_with ~suffix:".tig")
    |> List.map (fun name -> "/home/bordo/tigml/test/" ^ name)
  in

  let progs =
    [
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
    ]
  (*
  [
      "/home/bordo/tigml/test/test42.tig";
  ]
  *)
  in
  List.iter
      (fun program ->
        printf "Lexing program %s\n" program;
        let infile = open_in program in
        let file_content = really_input_string infile (in_channel_length infile) in
        let filebuf = Lexing.from_string file_content in
        process filebuf;
        close_in infile;
        printf "\n")
      progs
