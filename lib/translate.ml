open Tree

let ( let* ) = Result.bind

type exp = Tree.exp

type level =
  | Level of { parent : level; frame : Frame.frame; unique : unit ref }
  | Outermost
[@@deriving show]

type access = level * Frame.access [@@deriving show]

let global_fragments : Frame.fragment list ref = ref []
let outermost = Outermost
let outermost_frame = Frame.new_frame (Temp.named_label "main") []

let new_level parent name formals =
  let formals_with_link = true :: formals in
  (* Static link always escapes *)
  let frame = Frame.new_frame name formals_with_link in
  Level { parent; frame; unique = ref () }

let formals = function
  | Outermost -> []
  | Level { frame; parent = _; unique = _ } as level ->
      let frame_formals = Frame.formals frame in
      let without_static_link = List.tl frame_formals in
      (* Remove static link *)
      List.map (fun access -> (level, access)) without_static_link

let alloc_local (escape : bool) = function
  | Outermost ->
      let frame_access = Frame.alloc_local outermost_frame escape in
      (Outermost, frame_access)
  | Level { frame; parent = _; unique = _ } as level ->
      let frame_access = Frame.alloc_local frame escape in
      (level, frame_access)

let new_string s =
  let lab = Temp.new_label () in
  let frag = Frame.String (lab, s) in
  global_fragments := frag :: !global_fragments;
  Tree.Name lab

(* TODO *)
let simple_var venv tenv (access : access) : exp =
  (* Level has a frame and parent leve, access is a reg or temp *)
  let level, frame_access = access in
  match (level, frame_access) with
  | Level l, InFrame n -> Tree.Const 99
  | Level l, InReg temp -> Tree.Const 99
  | Outermost, InFrame n -> Tree.Const 99
  | Outermost, InReg temp -> Tree.Const 99

let map_binop = function
  | Absyn.PlusOp -> Ok Tree.Plus
  | Absyn.MinusOp -> Ok Tree.Minus
  | Absyn.TimesOp -> Ok Tree.Mul
  | Absyn.DivideOp -> Ok Tree.Div
  | _ -> Error `CantTreatBinopAsRelop

let map_relop = function
  | Absyn.EqOp -> Ok Tree.EQ
  | Absyn.NeqOp -> Ok Tree.NE
  | Absyn.LtOp -> Ok Tree.LT
  | Absyn.LeOp -> Ok Tree.LE
  | Absyn.GtOp -> Ok Tree.GT
  | Absyn.GeOp -> Ok Tree.GE
  | _ -> Error `CantTreatRelopAsBinop

let ( ++ ) s1 s2 = Seq (s1, s2)

(* lets just handle conditionals by setting a reg to 0 or 1 *)
let operation (l : Tree.exp) (r : Tree.exp) = function
  | (Absyn.PlusOp | Absyn.MinusOp | Absyn.TimesOp | Absyn.DivideOp) as op ->
      let* trans_op = map_binop op in
      Ok (Tree.Binop (trans_op, l, r))
  | ( Absyn.EqOp | Absyn.NeqOp | Absyn.LtOp | Absyn.LeOp | Absyn.GtOp
    | Absyn.GeOp ) as op ->
      (* TODO *)
      let* trans_op = map_relop op in
      let true_label = Temp.new_label () in
      let false_label = Temp.new_label () in
      let done_label = Temp.new_label () in
      let result = Temp.new_temp () in
      (* *)
      Ok
        (ESeq
           ( CJump (trans_op, l, r, true_label, false_label)
             ++ Label false_label
             ++ Move (Temp result, Const 0)
             ++ Jump (Name done_label, [ done_label ])
             ++ Label true_label
             ++ Move (Temp result, Const 1)
             ++ Label done_label,
             Temp result ))

let if' (test : Tree.exp) (then' : Tree.exp) (else' : Tree.exp) =
  let t = Temp.new_label () in
  let f = Temp.new_label () in
  let join = Temp.new_label () in
  let r = Temp.new_temp () in
  Ok
    (ESeq
       ( CJump (NE, test, Const 0, t, f)
         ++ Label t
         ++ Move (Temp r, then')
         ++ Jump (Name join, [ join ])
         ++ Label f
         ++ Move (Temp r, else')
         ++ Label join,
         Temp r ))
