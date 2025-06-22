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
let%test "record type and field access" = test_program "test3.tig" true
let%test "recursive function declaration" = test_program "test4.tig" true
let%test "mutually recursive types" = test_program "test5.tig" true
let%test "mutually recursive procedures" = test_program "test6.tig" true
let%test "mutually recursive functions" = test_program "test7.tig" true
let%test "simple if-then-else" = test_program "test8.tig" true
let%test "if-then-else type mismatch" = test_program "test9.tig" false
let%test "while body not unit" = test_program "test10.tig" false
let%test "for loop type errors" = test_program "test11.tig" false
let%test "valid for loop with assignment" = test_program "test12.tig" true
let%test "comparison type mismatch" = test_program "test13.tig" false
let%test "record vs array comparison" = test_program "test14.tig" false
let%test "if-then without else returns non-unit" = test_program "test15.tig" false
let%test "invalid recursive type cycle" = test_program "test16.tig" false
let%test "interrupted recursive type definition" = test_program "test17.tig" false
let%test "interrupted recursive function definition" = test_program "test18.tig" false
let%test "undeclared variable in function" = test_program "test19.tig" false
let%test "undeclared variable" = test_program "test20.tig" false
let%test "procedure used in arithmetic" = test_program "test21.tig" false
let%test "invalid record field access" = test_program "test22.tig" false
let%test "record field type mismatch" = test_program "test23.tig" false
let%test "array subscript on non-array" = test_program "test24.tig" false
let%test "field access on non-record" = test_program "test25.tig" false
let%test "arithmetic type mismatch" = test_program "test26.tig" false
let%test "local variable shadowing" = test_program "test27.tig" true
let%test "different record type assignment" = test_program "test28.tig" false
let%test "different array type assignment" = test_program "test29.tig" false
let%test "type synonym usage" = test_program "test30.tig" true
let%test "variable type constraint mismatch" = test_program "test31.tig" false
let%test "array initialization type mismatch" = test_program "test32.tig" false
let%test "unknown type in record creation" = test_program "test33.tig" false
let%test "function argument type mismatch" = test_program "test34.tig" false
let%test "too few function arguments" = test_program "test35.tig" false
let%test "too many function arguments" = test_program "test36.tig" false
let%test "valid variable redeclaration" = test_program "test37.tig" true
let%test "duplicate type names in batch" = test_program "test38.tig" false
let%test "duplicate function names in batch" = test_program "test39.tig" false
let%test "procedure returning value" = test_program "test40.tig" false
let%test "local type shadowing" = test_program "test41.tig" true
let%test "complex nested declarations" = test_program "test42.tig" true
let%test "unit initialization in arithmetic" = test_program "test43.tig" false
let%test "valid nil initialization" = test_program "test44.tig" true
let%test "unconstrained nil initialization" = test_program "test45.tig" false
let%test "valid record nil comparison" = test_program "test46.tig" true
let%test "non-consecutive duplicate types" = test_program "test47.tig" true
let%test "non-consecutive duplicate functions" = test_program "test48.tig" true
let%test "invalid nil syntax" = test_program "test49.tig" false
let%test "deep record nesting" = test_program "test50.tig" true
let%test "break outside loop" = test_program "test51.tig" false
let%test "valid break in loop" = test_program "test52.tig" true
let%test "variable escape analysis" = test_program "test53.tig" true
let%test "built-in string functions" = test_program "test54.tig" true
let%test "operator precedence" = test_program "test55.tig" true
let%test "merge sort program" = test_program "merge.tig" true
let%test "eight queens problem" = test_program "queens.tig" true
