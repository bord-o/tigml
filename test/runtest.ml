(* A module with functions to test *)
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
  let open Semant in
  let filebuf = buf_of_file prog in
  print_endline prog;
  try
    process filebuf;
    "pass"
  with
  | UnexpectedType (_, _) -> "fail: UnexpectedType"
  | IncorrectNumberOfArguments _ -> "fail: IncorrectNumberOfArguments"
  | IncorrectNumberOfFields _ -> "fail: IncorrectNumberOfFields"
  | UnboundIdentifier _ -> "fail: UnboundIdentifier"
  | CantReassignType (_, _) -> "fail: CantReassignType"

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
    (* "/home/bordo/tigml/test/test49.tig"; *)
    "/home/bordo/tigml/test/queens.tig";
    "/home/bordo/tigml/test/merge.tig";
    "/home/bordo/tigml/test/ast1.tig";
    "/home/bordo/tigml/test/ast2.tig";
    "/home/bordo/tigml/test/ast3.tig";
    "/home/bordo/tigml/test/ast4.tig";
    "/home/bordo/tigml/test/ast5.tig";
  ]

open Alcotest

let () = print_endline (List.nth progs 0)
let () = print_endline (List.nth progs 36)
let test_1 () = check string "Test 1" "pass" (run_prog @@ List.nth progs 0)

let test_2 () =
  Alcotest.(check string) "Test 2" "pass" (run_prog @@ List.nth progs 1)

let test_3 () =
  Alcotest.(check string) "Test 3" "pass" (run_prog @@ List.nth progs 2)

let test_4 () =
  Alcotest.(check string) "Test 4" "pass" (run_prog @@ List.nth progs 3)

let test_5 () =
  Alcotest.(check string) "Test 5" "pass" (run_prog @@ List.nth progs 4)

let test_6 () =
  Alcotest.(check string) "Test 6" "pass" (run_prog @@ List.nth progs 5)

let test_7 () =
  Alcotest.(check string) "Test 7" "pass" (run_prog @@ List.nth progs 6)

let test_8 () =
  Alcotest.(check string) "Test 8" "pass" (run_prog @@ List.nth progs 7)

let test_9 () =
  Alcotest.(check string)
    "Test 9" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 8)

let test_10 () =
  Alcotest.(check string)
    "Test 10" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 9)

let test_11 () =
  Alcotest.(check string)
    "Test 11" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 10)

let test_12 () =
  Alcotest.(check string) "Test 12" "pass" (run_prog @@ List.nth progs 11)

let test_13 () =
  Alcotest.(check string)
    "Test 13" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 12)

let test_14 () =
  Alcotest.(check string)
    "Test 14" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 13)

let test_15 () =
  Alcotest.(check string) "Test 15" "pass" (run_prog @@ List.nth progs 14)

let test_16 () =
  Alcotest.(check string) "Test 16" "pass" (run_prog @@ List.nth progs 15)

let test_17 () =
  Alcotest.(check string)
    "Test 17" "fail: UnboundIdentifier"
    (run_prog @@ List.nth progs 16)

let test_18 () =
  Alcotest.(check string) "Test 18" "pass" (run_prog @@ List.nth progs 17)

let test_19 () =
  Alcotest.(check string) "Test 19" "pass" (run_prog @@ List.nth progs 18)

let test_20 () =
  Alcotest.(check string) "Test 20" "pass" (run_prog @@ List.nth progs 19)

let test_21 () =
  Alcotest.(check string) "Test 21" "pass" (run_prog @@ List.nth progs 20)

let test_22 () =
  Alcotest.(check string)
    "Test 22" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 21)

let test_23 () =
  Alcotest.(check string)
    "Test 23" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 22)

let test_24 () =
  Alcotest.(check string)
    "Test 24" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 23)

let test_25 () =
  Alcotest.(check string)
    "Test 25" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 24)

let test_26 () =
  Alcotest.(check string)
    "Test 26" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 25)

let test_27 () =
  Alcotest.(check string) "Test 27" "pass" (run_prog @@ List.nth progs 26)

let test_28 () =
  Alcotest.(check string)
    "Test 28" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 27)

let test_29 () =
  Alcotest.(check string) "Test 29" "pass" (run_prog @@ List.nth progs 28)

let test_30 () =
  Alcotest.(check string) "Test 30" "pass" (run_prog @@ List.nth progs 29)

let test_31 () =
  Alcotest.(check string)
    "Test 31" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 30)

let test_32 () =
  Alcotest.(check string)
    "Test 32" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 31)

let test_33 () =
  Alcotest.(check string)
    "Test 33" "fail: UnboundIdentifier"
    (run_prog @@ List.nth progs 32)

let test_34 () =
  Alcotest.(check string)
    "Test 34" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 33)

let test_35 () =
  Alcotest.(check string)
    "Test 35" "fail: IncorrectNumberOfArguments"
    (run_prog @@ List.nth progs 34)

let test_36 () =
  Alcotest.(check string)
    "Test 36" "fail: IncorrectNumberOfArguments"
    (run_prog @@ List.nth progs 35)

let test_37 () =
  Alcotest.(check string) "Test 37" "pass" (run_prog @@ List.nth progs 36)

let test_38 () =
  Alcotest.(check string)
    "Test 38" "fail: CantReassignType"
    (run_prog @@ List.nth progs 37)

let test_39 () =
  Alcotest.(check string) "Test 39" "pass" (run_prog @@ List.nth progs 38)

let test_40 () =
  Alcotest.(check string) "Test 40" "pass" (run_prog @@ List.nth progs 39)

let test_41 () =
  Alcotest.(check string) "Test 41" "pass" (run_prog @@ List.nth progs 40)

let test_42 () =
  Alcotest.(check string) "Test 42" "pass" (run_prog @@ List.nth progs 41)

let test_43 () =
  Alcotest.(check string)
    "Test 43" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 42)

let test_44 () =
  Alcotest.(check string) "Test 44" "pass" (run_prog @@ List.nth progs 43)

let test_45 () =
  Alcotest.(check string)
    "Test 45" "fail: UnexpectedType"
    (run_prog @@ List.nth progs 44)

let test_46 () =
  Alcotest.(check string) "Test 46" "pass" (run_prog @@ List.nth progs 45)

let test_47 () =
  Alcotest.(check string) "Test 47" "pass" (run_prog @@ List.nth progs 46)

let test_48 () =
  Alcotest.(check string) "Test 48" "pass" (run_prog @@ List.nth progs 47)

let test_queens () =
  Alcotest.(check string) "Test queens" "pass" (run_prog @@ List.nth progs 48)

let test_merge () =
  Alcotest.(check string) "Test Merge" "pass" (run_prog @@ List.nth progs 49)

(* Run it *)
let () =
  let test = Alcotest.test_case in
  Alcotest.run "Tigml"
    [
      ( "program tests",
        [
          test "Test 1" `Quick @@ test_1;
          test "Test 2" `Quick @@ test_2;
          test "Test 3" `Quick @@ test_3;
          test "Test 4" `Quick @@ test_4;
          test "Test 5" `Quick @@ test_5;
          test "Test 6" `Quick @@ test_6;
          test "Test 7" `Quick @@ test_7;
          test "Test 8" `Quick @@ test_8;
          test "Test 9" `Quick @@ test_9;
          test "Test 10" `Quick @@ test_10;
          test "Test 11" `Quick @@ test_11;
          test "Test 12" `Quick @@ test_12;
          test "Test 13" `Quick @@ test_13;
          test "Test 14" `Quick @@ test_14;
          test "Test 15" `Quick @@ test_15;
          test "Test 16" `Quick @@ test_16;
          test "Test 17" `Quick @@ test_17;
          test "Test 18" `Quick @@ test_18;
          test "Test 19" `Quick @@ test_19;
          test "Test 20" `Quick @@ test_20;
          test "Test 21" `Quick @@ test_21;
          test "Test 22" `Quick @@ test_22;
          test "Test 23" `Quick @@ test_23;
          test "Test 24" `Quick @@ test_24;
          test "Test 25" `Quick @@ test_25;
          test "Test 26" `Quick @@ test_26;
          test "Test 27" `Quick @@ test_27;
          (* TODO: Should error when record types arent the same even fields are the same*)
          test "Test 28" `Quick @@ test_28;
          test "Test 29" `Quick @@ test_29;
          test "Test 30" `Quick @@ test_30;
          test "Test 31" `Quick @@ test_31;
          test "Test 32" `Quick @@ test_32;
          test "Test 33" `Quick @@ test_33;
          test "Test 34" `Quick @@ test_34;
          test "Test 35" `Quick @@ test_35;
          test "Test 36" `Quick @@ test_36;
          test "Test 37" `Quick @@ test_37;
          (*  TODO: Cant reassign types *)
          test "Test 38" `Quick @@ test_38;
          test "Test 39" `Quick @@ test_39;
          test "Test 40" `Quick @@ test_40;
          test "Test 41" `Quick @@ test_41;
          test "Test 42" `Quick @@ test_42;
          test "Test 43" `Quick @@ test_43;
          (*  TODO: Should be able to assign nil to record type *)
          test "Test 44" `Quick @@ test_44;
          (* TODO: Shouldn't be able set nil to a non record type *)
          test "Test 45" `Quick @@ test_45;
          (* TODO: Should be able to compare record to nil type *)
          test "Test 46" `Quick @@ test_46;
          test "Test 47" `Quick @@ test_47;
          (* TODO: more local binding shadowing *)
          test "Test 48" `Quick @@ test_48;
          test "Test Queens" `Quick @@ test_queens;
          (* TODO: add proper values to start environment to simulate stdlib *)
          test "Test Merge" `Quick @@ test_merge;
          (* *)
        ] );
    ]
