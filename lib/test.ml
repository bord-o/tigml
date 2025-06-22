let%expect_test "record expression translation 2 fields" =
  let fields = [ Tree.Const 1; Tree.Const 2 ] in
  let ir = Translate.record_exp fields in
  print_endline @@ Tree.show_exp ir;
  [%expect
    {|
    (Tree.ESeq (
       (Tree.Seq (
          (Tree.Seq (
             (Tree.Move ((Tree.Temp 5),
                (Tree.Call ((Tree.Name ("init_array", 1)), [(Tree.Const 16)])))),
             (Tree.Move ((Tree.Binop (Tree.Plus, (Tree.Temp 5), (Tree.Const 0))),
                (Tree.Const 1)))
             )),
          (Tree.Move ((Tree.Binop (Tree.Plus, (Tree.Temp 5), (Tree.Const 8))),
             (Tree.Const 2)))
          )),
       (Tree.Temp 5)))
    |}]

let%expect_test "record expression translation 2 fields" =
  let fields = [] in
  let ir = Translate.record_exp fields in
  print_endline @@ Tree.show_exp ir;
  [%expect {|
    |}]
