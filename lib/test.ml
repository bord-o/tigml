let show_exceptions = false

let test_program filename should_pass =
  try
    let filepath = "../test_programs/" ^ filename in
    let infile = open_in filepath in
    let file_content = really_input_string infile (in_channel_length infile) in
    let filebuf = Lexing.from_string file_content in
    let absyn = Parser.main Lexer.token filebuf in
    Semant.typecheckProg absyn;
    close_in infile;
    should_pass
  with e ->
    if show_exceptions then print_endline @@ Printexc.to_string e;
    not should_pass

let%test "array type and var" = test_program "test1.tig" true
let%test "array type using declared type" = test_program "test2.tig" true
let%test "test3.tig" = test_program "test3.tig" true
let%test "test4.tig" = test_program "test4.tig" true
let%test "test5.tig" = test_program "test5.tig" true
let%test "test6.tig" = test_program "test6.tig" true
let%test "test7.tig" = test_program "test7.tig" true
let%test "test8.tig" = test_program "test8.tig" true
let%test "test9.tig" = test_program "test9.tig" false
let%test "test10.tig" = test_program "test10.tig" false
let%test "test11.tig" = test_program "test11.tig" false
let%test "test12.tig" = test_program "test12.tig" true
let%test "test13.tig" = test_program "test13.tig" false
let%test "test14.tig" = test_program "test14.tig" false
let%test "test15.tig" = test_program "test15.tig" false
let%test "test16.tig" = test_program "test16.tig" false
let%test "test17.tig" = test_program "test17.tig" false
let%test "test18.tig" = test_program "test18.tig" false
let%test "test19.tig" = test_program "test19.tig" false
let%test "test20.tig" = test_program "test20.tig" false
let%test "test21.tig" = test_program "test21.tig" false
let%test "test22.tig" = test_program "test22.tig" false
let%test "test23.tig" = test_program "test23.tig" false
let%test "test24.tig" = test_program "test24.tig" false
let%test "test25.tig" = test_program "test25.tig" false
let%test "test26.tig" = test_program "test26.tig" false
let%test "test27.tig" = test_program "test27.tig" true
let%test "test28.tig" = test_program "test28.tig" false
let%test "test29.tig" = test_program "test29.tig" false
let%test "test30.tig" = test_program "test30.tig" true
let%test "test31.tig" = test_program "test31.tig" false
let%test "test32.tig" = test_program "test32.tig" false
let%test "test33.tig" = test_program "test33.tig" false
let%test "test34.tig" = test_program "test34.tig" false
let%test "test35.tig" = test_program "test35.tig" false
let%test "test36.tig" = test_program "test36.tig" false
let%test "test37.tig" = test_program "test37.tig" true
let%test "test38.tig" = test_program "test38.tig" false
let%test "test39.tig" = test_program "test39.tig" false
let%test "test40.tig" = test_program "test40.tig" false
let%test "test41.tig" = test_program "test41.tig" true
let%test "test42.tig" = test_program "test42.tig" true
let%test "test43.tig" = test_program "test43.tig" false
let%test "test44.tig" = test_program "test44.tig" true
let%test "test45.tig" = test_program "test45.tig" false
let%test "test46.tig" = test_program "test46.tig" true
let%test "test47.tig" = test_program "test47.tig" true
let%test "test48.tig" = test_program "test48.tig" true
let%test "test49.tig" = test_program "test49.tig" false
let%test "test50.tig" = test_program "test50.tig" true
let%test "test51.tig" = test_program "test51.tig" false
let%test "test52.tig" = test_program "test52.tig" true
let%test "test53.tig" = test_program "test53.tig" true
let%test "test54.tig" = test_program "test54.tig" true
let%test "test55.tig" = test_program "test55.tig" true
let%test "merge.tig" = test_program "merge.tig" true
let%test "queens.tig" = test_program "queens.tig" true
