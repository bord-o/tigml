open Tigml

let process buf =
  try
    (* Run the parser on this line of input. *)
    let absyn = Parser.main Lexer.token buf in
    (* print_endline @@ Tigml.Absyn.show_exp absyn; *)
    print_endline "Parse success!";
    Tigml.Semant.typecheckProg absyn

  with
  | Parser.Error -> raise Parser.Error
  | Lexer.Error msg -> print_endline @@ "lexer error: " ^ msg

let () =
  let open Printf in
  let _dirs =
    Sys.readdir "/Users/brodylittle/Git/tigml/test/"
    |> Array.to_list
    |> List.filter (String.ends_with ~suffix:".tig")
    |> List.map (fun name -> "/Users/brodylittle/Git/tigml/test/" ^ name)
  in

  let progs =
    [
      (* "/Users/brodylittle/Git/tigml/test/test1.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test2.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test3.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test4.tig"; *)
      "/Users/brodylittle/Git/tigml/test/test5.tig";
      (* "/Users/brodylittle/Git/tigml/test/test6.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test7.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test8.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test9.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test10.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test11.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test12.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test13.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test14.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test15.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test16.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test17.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test18.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test18.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test19.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test20.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test21.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test22.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test23.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test24.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test25.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test26.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test27.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test28.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test29.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test30.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test31.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test32.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test33.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test34.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test35.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test36.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test37.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test38.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test39.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test40.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test41.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test42.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test43.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test44.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test45.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test46.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test47.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test48.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/test49.tig";  this is supposed to syntax error*)
      (* "/Users/brodylittle/Git/tigml/test/merge.tig"; *)
	  (* "/Users/brodylittle/Git/tigml/test/ast1.tig"; *)
  	  (* "/Users/brodylittle/Git/tigml/test/ast2.tig"; *)
	  (* "/Users/brodylittle/Git/tigml/test/ast3.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/ast4.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/ast5.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/ast5.tig"; *)
      (* "/Users/brodylittle/Git/tigml/test/queens.tig"; *)
    ]
  in

  List.iter
    (fun program ->
      printf "Lexing program %s\n" program;
      let infile = open_in program in
      let file_content =
        really_input_string infile (in_channel_length infile)
      in
      let filebuf = Lexing.from_string file_content in
      process filebuf;
      close_in infile;
      printf "\n")
    progs
