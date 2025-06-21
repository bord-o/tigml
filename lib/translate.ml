open Tree

let ( let* ) = Result.bind

type exp = Tree.exp

type level =
  | Level of { parent : level; frame : Frame.frame; unique : unit ref }
  | Outermost
[@@deriving show]

let level_eq a b =
  match (a, b) with
  | Outermost, Outermost -> true
  | Level { unique = u1 }, Level { unique = u2 } when u1 = u2 -> true
  | _ -> false

type access = level * Frame.access [@@deriving show]

type break_context = Temp.label option

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

(* TODO: Test this*)
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

let break' (break_context : break_context) (pos : Absyn.pos) =
  match break_context with
  | None -> Error (`BreakUsedOutsideOfLoop pos) (* This should be caught in semantic analysis *)
  | Some exit_label -> Ok (ESeq (Jump (Name exit_label, [ exit_label ]), Const 0))

let while' (test : exp) (body : exp) (done_label : Temp.label) =
  let test_label = Temp.new_label () in
  let body_label = Temp.new_label () in
  Ok
    (ESeq
       ( Label test_label
         ++ CJump (EQ, test, Const 0, done_label, body_label)
         ++ Label body_label
         ++ Exp body
         ++ Jump (Name test_label, [ test_label ])
         ++ Label done_label,
         Const 0 ))

(* TODO: Test this*)
let if' (test : Tree.exp) (then' : Tree.exp) (else' : Tree.exp) =
  let true_label = Temp.new_label () in
  let false_label = Temp.new_label () in
  let done_label = Temp.new_label () in
  let result = Temp.new_temp () in
  Ok
    (ESeq
       ( CJump (NE, test, Const 0, true_label, false_label)
         ++ Label true_label
         ++ Move (Temp result, then')
         ++ Jump (Name done_label, [ done_label ])
         ++ Label false_label
         ++ Move (Temp result, else')
         ++ Label done_label,
         Temp result ))

(* TODO: Test this*)
let seq (exps : Tree.exp list) =
  match List.rev exps with
  | [] -> Const 0
  | last :: rest ->
      let build_seq_stmt = function
        | [] -> Exp (Const 0) (* Could also use a no-op statement *)
        | exps ->
            let stmts = List.map (fun e -> Exp e) exps in
            List.fold_left
              (fun acc s -> Seq (acc, s))
              (List.hd stmts) (List.tl stmts)
      in
      ESeq (build_seq_stmt (List.rev rest), last)

let get_frame = function Outermost -> outermost_frame | Level l -> l.frame
let get_parent = function Outermost -> None | Level l -> Some l.parent

(* TODO: Test this*)
(* Here lg is where the variable is declared and lf is where its used *)
let rec traverse_static_links ~(dec_level : level) ~(use_level : level) fp =
  if level_eq dec_level use_level then
    (* Same level - just return the frame pointer *)
    Ok fp
  else
    match use_level with
    | Outermost -> Ok fp
    | Level l -> (
        (* Get the static link from the current frame *)
        let current_frame = l.frame in
        let static_link = List.hd (Frame.formals current_frame) in
        match static_link with
        | Frame.InReg _ -> Error (`StaticLinkShouldNotBeInReg current_frame)
        | Frame.InFrame offset ->
            (* Follow the static link *)
            let static_link_addr = Mem (Binop (Plus, fp, Const offset)) in
            traverse_static_links ~dec_level ~use_level:l.parent
              static_link_addr)

(* TODO: Test this*)
let simple_var (access : access) ty (use_level : level) =
  let dec_level, frame_access = access in
  match frame_access with
  | Frame.InReg temp -> Ok (Temp temp)
  | Frame.InFrame offset when level_eq dec_level use_level ->
      Ok (Mem (Binop (Plus, Temp Frame.fp, Const offset)))
  | Frame.InFrame offset ->
      let* target_fp = traverse_static_links ~dec_level ~use_level (Temp Frame.fp) in
      Ok (Mem (Binop (Plus, target_fp, Const offset)))

let static_link_for_call ~(callee_level : level) ~(current_level : level) =
  match callee_level with
  | Outermost ->
      (* Even outermost functions need a static link to access globals *)
      (* The static link should point to the outermost_frame *)
      traverse_static_links ~dec_level:Outermost ~use_level:current_level
        (Temp Frame.fp)
  | Level { parent; _ } ->
      (* Find the frame pointer of the callee's parent *)
      traverse_static_links ~dec_level:parent ~use_level:current_level
        (Temp Frame.fp)

(*
    Need to find the level of the enclosing environment  of the function and pass a pointer to that so that the function body can access variables at that level
*)
let call label (args : exp list) dec_level call_level =
  let* static_link =
    static_link_for_call ~callee_level:dec_level ~current_level:call_level
  in
  let args_with_link = static_link :: args in
  Ok (Call (Name label, args_with_link))
