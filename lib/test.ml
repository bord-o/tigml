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
                (Tree.Call ((Tree.Name ("init_record", 1)), [(Tree.Const 16)])))),
             (Tree.Move ((Tree.Binop (Tree.Plus, (Tree.Temp 5), (Tree.Const 0))),
                (Tree.Const 1)))
             )),
          (Tree.Move ((Tree.Binop (Tree.Plus, (Tree.Temp 5), (Tree.Const 8))),
             (Tree.Const 2)))
          )),
       (Tree.Temp 5)))
    |}]

let%expect_test "record expression translation 0 fields" =
  let fields = [] in
  let ir = Translate.record_exp fields in
  print_endline @@ Tree.show_exp ir;
  [%expect
    {|
    (Tree.ESeq (
       (Tree.Move ((Tree.Temp 6),
          (Tree.Call ((Tree.Name ("init_record", 1)), [(Tree.Const 0)])))),
       (Tree.Temp 6)))
    |}]

let%expect_test "array expression translation length 3" =
  let ir = Translate.array_exp ~size:(Tree.Const 3) ~init:(Tree.Const 99) in
  print_endline @@ Tree.show_exp ir;
  [%expect
    {|
    (Tree.ESeq (
       (Tree.Move ((Tree.Temp 7),
          (Tree.Call ((Tree.Name ("init_record", 1)),
             [(Tree.Const 3); (Tree.Const 99)]))
          )),
       (Tree.Temp 7)))
    |}]
