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
  let filebuf = buf_of_file prog in
  print_endline prog;
  try
    process filebuf;
    "pass"
  with _ -> "fail"

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
    "/home/bordo/tigml/test/test43.tig";
    "/home/bordo/tigml/test/test44.tig";
    "/home/bordo/tigml/test/test45.tig";
    "/home/bordo/tigml/test/test46.tig";
    "/home/bordo/tigml/test/test47.tig";
    "/home/bordo/tigml/test/test48.tig";
    "/home/bordo/tigml/test/test49.tig";
    "/home/bordo/tigml/test/merge.tig";
    "/home/bordo/tigml/test/queens.tig";
    "/home/bordo/tigml/test/ast1.tig";
    "/home/bordo/tigml/test/ast2.tig";
    "/home/bordo/tigml/test/ast3.tig";
    "/home/bordo/tigml/test/ast4.tig";
    "/home/bordo/tigml/test/ast5.tig";
  ]

open Alcotest

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
  Alcotest.(check string) "Test 9" "fail" (run_prog @@ List.nth progs 8)

let test_10 () =
  Alcotest.(check string) "Test 10" "fail" (run_prog @@ List.nth progs 9)

let test_11 () =
  Alcotest.(check string) "Test 11" "fail" (run_prog @@ List.nth progs 10)

let test_12 () =
  Alcotest.(check string) "Test 12" "pass" (run_prog @@ List.nth progs 11)

let test_13 () =
  Alcotest.(check string) "Test 13" "fail" (run_prog @@ List.nth progs 12)

let test_14 () =
  Alcotest.(check string) "Test 14" "fail" (run_prog @@ List.nth progs 13)

let test_15 () =
  Alcotest.(check string) "Test 15" "pass" (run_prog @@ List.nth progs 14)

let test_16 () =
  Alcotest.(check string) "Test 16" "pass" (run_prog @@ List.nth progs 15)

let test_17 () =
  Alcotest.(check string) "Test 17" "fail" (run_prog @@ List.nth progs 16)

let test_18 () =
  Alcotest.(check string) "Test 18" "pass" (run_prog @@ List.nth progs 17)

let test_19 () =
  Alcotest.(check string) "Test 19" "pass" (run_prog @@ List.nth progs 18)

let test_20 () =
  Alcotest.(check string) "Test 20" "pass" (run_prog @@ List.nth progs 19)

let test_21 () =
  Alcotest.(check string) "Test 21" "pass" (run_prog @@ List.nth progs 20)

let test_22 () =
  Alcotest.(check string) "Test 22" "pass" (run_prog @@ List.nth progs 21)

let test_23 () =
  Alcotest.(check string) "Test 23" "fail" (run_prog @@ List.nth progs 22)

let test_24 () =
  Alcotest.(check string) "Test 24" "fail" (run_prog @@ List.nth progs 23)

let test_25 () =
  Alcotest.(check string) "Test 25" "fail" (run_prog @@ List.nth progs 24)

let test_26 () =
  Alcotest.(check string) "Test 26" "fail" (run_prog @@ List.nth progs 25)

let test_27 () =
  Alcotest.(check string) "Test 27" "pass" (run_prog @@ List.nth progs 26)

let test_28 () =
  Alcotest.(check string) "Test 28" "pass" (run_prog @@ List.nth progs 27)

let test_29 () =
  Alcotest.(check string) "Test 29" "pass" (run_prog @@ List.nth progs 28)

let test_30 () =
  Alcotest.(check string) "Test 30" "pass" (run_prog @@ List.nth progs 29)

let test_31 () =
  Alcotest.(check string) "Test 31" "pass" (run_prog @@ List.nth progs 30)

let test_32 () =
  Alcotest.(check string) "Test 32" "fail" (run_prog @@ List.nth progs 31)

let test_33 () =
  Alcotest.(check string) "Test 33" "fail" (run_prog @@ List.nth progs 32)

let test_34 () =
  Alcotest.(check string) "Test 34" "fail" (run_prog @@ List.nth progs 33)

let test_35 () =
  Alcotest.(check string) "Test 35" "fail" (run_prog @@ List.nth progs 34)

let test_36 () =
  Alcotest.(check string) "Test 36" "fail" (run_prog @@ List.nth progs 35)

let test_37 () =
  Alcotest.(check string) "Test 37" "pass" (run_prog @@ List.nth progs 36)

let test_38 () =
  Alcotest.(check string) "Test 38" "pass" (run_prog @@ List.nth progs 37)

let test_39 () =
  Alcotest.(check string) "Test 39" "pass" (run_prog @@ List.nth progs 38)

let test_40 () =
  Alcotest.(check string) "Test 40" "pass" (run_prog @@ List.nth progs 39)

let test_41 () =
  Alcotest.(check string) "Test 41" "pass" (run_prog @@ List.nth progs 40)

let test_42 () =
  Alcotest.(check string) "Test 42" "pass" (run_prog @@ List.nth progs 41)

let test_43 () =
  Alcotest.(check string) "Test 43" "pass" (run_prog @@ List.nth progs 42)

let test_44 () =
  Alcotest.(check string) "Test 44" "pass" (run_prog @@ List.nth progs 43)

let test_45 () =
  Alcotest.(check string) "Test 45" "fail" (run_prog @@ List.nth progs 44)

let test_46 () =
  Alcotest.(check string) "Test 46" "pass" (run_prog @@ List.nth progs 45)

let test_47 () =
  Alcotest.(check string) "Test 47" "pass" (run_prog @@ List.nth progs 46)

let test_48 () =
  Alcotest.(check string) "Test 48" "pass" (run_prog @@ List.nth progs 47)

(* Run it *)
let () =
  Alcotest.run "Tigml"
    [
      ( "program tests",
        [
          Alcotest.test_case "Test 1" `Quick @@ test_1;
          Alcotest.test_case "Test 2" `Quick @@ test_2;
          Alcotest.test_case "Test 3" `Quick @@ test_3;
          Alcotest.test_case "Test 4" `Quick @@ test_4;
          Alcotest.test_case "Test 5" `Quick @@ test_5;
          Alcotest.test_case "Test 6" `Quick @@ test_6;
          Alcotest.test_case "Test 7" `Quick @@ test_7;
          Alcotest.test_case "Test 8" `Quick @@ test_8;
          Alcotest.test_case "Test 9" `Quick @@ test_9;
          Alcotest.test_case "Test 10" `Quick @@ test_10;
          Alcotest.test_case "Test 11" `Quick @@ test_11;
          Alcotest.test_case "Test 12" `Quick @@ test_12;
          Alcotest.test_case "Test 13" `Quick @@ test_13;
          Alcotest.test_case "Test 14" `Quick @@ test_14;
          Alcotest.test_case "Test 15" `Quick @@ test_15;
          Alcotest.test_case "Test 16" `Quick @@ test_16;
          Alcotest.test_case "Test 17" `Quick @@ test_17;
          Alcotest.test_case "Test 18" `Quick @@ test_18;
          Alcotest.test_case "Test 19" `Quick @@ test_19;
          Alcotest.test_case "Test 20" `Quick @@ test_20;
          Alcotest.test_case "Test 21" `Quick @@ test_21;
          Alcotest.test_case "Test 22" `Quick @@ test_22;
          Alcotest.test_case "Test 23" `Quick @@ test_23;
          Alcotest.test_case "Test 24" `Quick @@ test_24;
          Alcotest.test_case "Test 25" `Quick @@ test_25;
          Alcotest.test_case "Test 26" `Quick @@ test_26;
          Alcotest.test_case "Test 27" `Quick @@ test_27;
          (*  TODO: This local bindings work *)
          Alcotest.test_case "Test 28" `Quick @@ test_28;
          Alcotest.test_case "Test 29" `Quick @@ test_29;
          Alcotest.test_case "Test 30" `Quick @@ test_30;
          Alcotest.test_case "Test 31" `Quick @@ test_31;
          Alcotest.test_case "Test 32" `Quick @@ test_32;
          Alcotest.test_case "Test 33" `Quick @@ test_33;
          Alcotest.test_case "Test 34" `Quick @@ test_34;
          Alcotest.test_case "Test 35" `Quick @@ test_35;
          Alcotest.test_case "Test 36" `Quick @@ test_36;
          Alcotest.test_case "Test 37" `Quick @@ test_37;
          (*  TODO: more local binding problems *)
          Alcotest.test_case "Test 38" `Quick @@ test_38;
          Alcotest.test_case "Test 39" `Quick @@ test_39;
          Alcotest.test_case "Test 40" `Quick @@ test_40;
          Alcotest.test_case "Test 41" `Quick @@ test_41;
          Alcotest.test_case "Test 42" `Quick @@ test_42;
          Alcotest.test_case "Test 43" `Quick @@ test_43;
          Alcotest.test_case "Test 44" `Quick @@ test_44;
          (*  TODO: Nil problems *)
          Alcotest.test_case "Test 45" `Quick @@ test_45;
          Alcotest.test_case "Test 46" `Quick @@ test_46;
          Alcotest.test_case "Test 47" `Quick @@ test_47;
          (* TODO: more local binding shadowing *)
          Alcotest.test_case "Test 48" `Quick @@ test_48;
          (* *)
        ] );
    ]
