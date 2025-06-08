open Tigml

let () =
  let open Printf in
  let progs =
    [
      ("test1.tig", true);
      ("test2.tig", true);
      ("test3.tig", true);
      ("test4.tig", true);
      ("test5.tig", true);
      ("test6.tig", true);
      ("test7.tig", true);
      ("test8.tig", true);
      ("test9.tig", false);
      ("test10.tig", false);
      ("test11.tig", false);
      ("test12.tig", true);
      ("test13.tig", false);
      ("test14.tig", false);
      ("test15.tig", true);
      ("test16.tig", true);
      ("test17.tig", false);
      ("test18.tig", true);
      ("test18.tig", true);
      ("test19.tig", true);
      ("test20.tig", true);
      ("test21.tig", false);
      ("test22.tig", false);
      ("test23.tig", false);
      ("test24.tig", false);
      ("test25.tig", false);
      ("test26.tig", false);
      ("test27.tig", true);
      ("test28.tig", false);
      ("test29.tig", false);
      ("test30.tig", true);
      ("test31.tig", false);
      ("test32.tig", false);
      ("test33.tig", false);
      ("test34.tig", false);
      ("test35.tig", false);
      ("test36.tig", false);
      ("test37.tig", true);
      ("test38.tig", true);
      ("test39.tig", true);
      ("test40.tig", false);
      ("test41.tig", true);
      ("test42.tig", true);
      ("test43.tig", false);
      ("test44.tig", true);
      ("test45.tig", false);
      ("test46.tig", true);
      ("test47.tig", true);
      ("test48.tig", true);
      ("test49.tig", false);
      ("merge.tig", true);
      ("queens.tig", true);
    ]
  in

  let test_program (filename, should_pass) =
    printf "Testing %s... " filename;
    try
      let filepath = "/Users/brodylittle/Git/tigml/test/" ^ filename in
      let infile = open_in filepath in
      let file_content =
        really_input_string infile (in_channel_length infile)
      in
      let filebuf = Lexing.from_string file_content in
      let absyn = Parser.main Lexer.token filebuf in
      (* print_endline @@ Absyn.show_exp absyn; *)
      Tigml.Semant.typecheckProg absyn;
      close_in infile;
      if should_pass then printf "✅ PASS\n" else printf "❌ SHOULD HAVE FAILED\n"
    with e ->
      (* print_endline @@ Printexc.to_string e; *)
      if should_pass then printf "❌ FAIL\n" else printf "✅ EXPECTED FAIL\n"
  in
  List.iter test_program progs
