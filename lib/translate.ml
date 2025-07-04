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
  | Level { unique = u1; _ }, Level { unique = u2; _ } when u1 = u2 -> true
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

let new_func frame body = 
  let lab = Temp.new_label () in
  let frag = Frame.Proc {
      frame;
      body
  }  in
  global_fragments := frag :: !global_fragments;
  Tree.Label lab

let new_string s =
  let lab = Temp.new_label () in
  let frag = Frame.String (lab, s) in
  global_fragments := frag :: !global_fragments;
  Tree.Name lab

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

let rec traverse_static_links ~(dec_level : level) ~(use_level : level) fp =
  if level_eq dec_level use_level then Ok fp
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

let simple_var (access : access) (use_level : level) =
  let dec_level, frame_access = access in
  match frame_access with
  | Frame.InReg temp -> Ok (Temp temp)
  | Frame.InFrame offset when level_eq dec_level use_level ->
      Ok (Mem (Binop (Plus, Temp Frame.fp, Const offset)))
  | Frame.InFrame offset ->
      let* target_fp =
        traverse_static_links ~dec_level ~use_level (Temp Frame.fp)
      in
      Ok (Mem (Binop (Plus, target_fp, Const offset)))

(* lets just handle conditionals by setting a reg to 0 or 1 *)
let operation (l : Tree.exp) (r : Tree.exp) = function
  | (Absyn.PlusOp | Absyn.MinusOp | Absyn.TimesOp | Absyn.DivideOp) as op ->
      let* trans_op = map_binop op in
      Ok (Tree.Binop (trans_op, l, r))
  | ( Absyn.EqOp | Absyn.NeqOp | Absyn.LtOp | Absyn.LeOp | Absyn.GtOp
    | Absyn.GeOp ) as op ->
      let* trans_op = map_relop op in
      let true_label = Temp.new_label () in
      let false_label = Temp.new_label () in
      let done_label = Temp.new_label () in
      let result = Temp.new_temp () in
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
  | None -> Error (`BreakUsedOutsideOfLoop pos)
  | Some exit_label ->
      Ok (ESeq (Jump (Name exit_label, [ exit_label ]), Const 0))

let while' (test : exp) (body : exp) (done_label : Temp.label) =
  let test_label = Temp.new_label () in
  let body_label = Temp.new_label () in
  Ok
    (ESeq
       ( Label test_label
         ++ CJump (EQ, test, Const 0, done_label, body_label)
         ++ Label body_label ++ Exp body
         ++ Jump (Name test_label, [ test_label ])
         ++ Label done_label,
         Const 0 ))

let for' (var_access : access) (lo : exp) (hi : exp) (body : exp)
    (done_label : Temp.label) (current_level : level) =
  let test_label = Temp.new_label () in
  let body_label = Temp.new_label () in
  let* var_exp = simple_var var_access current_level in
  Ok
    (ESeq
       ( Move (var_exp, lo)
         ++ Label test_label
         ++ CJump (GT, var_exp, hi, done_label, body_label)
         ++ Label body_label ++ Exp body
         ++ Move (var_exp, Binop (Plus, var_exp, Const 1))
         ++ Jump (Name test_label, [ test_label ])
         ++ Label done_label,
         Const 0 ))

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

let seq (exps : Tree.exp list) =
  match List.rev exps with
  | [] -> Const 0
  | last :: rest ->
      let build_seq_stmt = function
        | [] -> Exp (Const 0)
        | exps ->
            let stmts = List.map (fun e -> Exp e) exps in
            List.fold_left
              (fun acc s -> Seq (acc, s))
              (List.hd stmts) (List.tl stmts)
      in
      ESeq (build_seq_stmt (List.rev rest), last)

let get_frame = function Outermost -> outermost_frame | Level l -> l.frame
let get_parent = function Outermost -> None | Level l -> Some l.parent

let static_link_for_call ~(callee_level : level) ~(current_level : level) =
  match callee_level with
  | Outermost ->
      traverse_static_links ~dec_level:Outermost ~use_level:current_level
        (Temp Frame.fp)
  | Level { parent; _ } ->
      traverse_static_links ~dec_level:parent ~use_level:current_level
        (Temp Frame.fp)

let call label (args : exp list) dec_level call_level =
  let* static_link =
    static_link_for_call ~callee_level:dec_level ~current_level:call_level
  in
  let args_with_link = static_link :: args in
  Ok (Call (Name label, args_with_link))

let field_var (record_exp : exp) (field_symbol : Symbol.symbol)
    (record_fields : (Symbol.symbol * Types.ty) list) =
  let rec find_field_offset offset = function
    | [] -> None
    | (sym, _) :: _ when sym = field_symbol -> Some offset
    | _ :: rest -> find_field_offset (offset + Frame.word_size) rest
  in
  match find_field_offset 0 record_fields with
  | Some field_offset -> Ok (Mem (Binop (Plus, record_exp, Const field_offset)))
  | None -> failwith "Field not found - should be caught in semantic analysis"

let subscript_var (array_exp : exp) (index_exp : exp) =
  Ok
    (Mem
       (Binop (Plus, array_exp, Binop (Mul, index_exp, Const Frame.word_size))))

let assign (var_access : access) (exp_value : exp) (current_level : level) =
  let* var_location = simple_var var_access current_level in
  Ok (ESeq (Move (var_location, exp_value), Const 0))

let assign_field (record_exp : exp) (field_symbol : Symbol.symbol)
    (record_fields : (Symbol.symbol * Types.ty) list) (exp_value : exp) =
  let* field_location = field_var record_exp field_symbol record_fields in
  Ok (ESeq (Move (field_location, exp_value), Const 0))

let assign_subscript (array_exp : exp) (index_exp : exp) (exp_value : exp) =
  let* subscript_location = subscript_var array_exp index_exp in
  Ok (ESeq (Move (subscript_location, exp_value), Const 0))

let record_exp (fields : exp list) =
  let alloc_size = Const (Frame.word_size * List.length fields) in
  let alloc_loc = Temp.new_temp () in
  let alloc_ir =
    Move (Temp alloc_loc, Frame.external_call "init_record" [ alloc_size ])
  in
  let rec init_fields offset acc = function
    | [] -> acc
    | f :: fs ->
        init_fields (succ offset)
          (acc
          ++ Move
               ( Binop (Plus, Temp alloc_loc, Const (offset * Frame.word_size)),
                 f ))
          fs
  in
  ESeq (init_fields 0 alloc_ir fields, Temp alloc_loc)

let array_exp ~(size : exp) ~(init : exp) =
  let alloc_loc = Temp.new_temp () in
  ESeq
    ( Move (Temp alloc_loc, Frame.external_call "init_array" [ size; init ]),
      Temp alloc_loc )

let var_dec (alloc_loc : access) level (init_ir : exp) =
  let* var_ir = simple_var alloc_loc level in
  Ok (Move (var_ir, init_ir))

let let_exp (decs : stm list) (body : exp) =
  let reduce f l =
    match l with [] -> None | x :: xs -> Some (xs |> List.fold_left f x)
  in
  match reduce ( ++ ) decs with
  | Some sequenced -> Ok (ESeq (sequenced, body))
  | None -> Ok body

let fun_dec_bodies (decs : stm list) =
  let reduce f l =
    match l with [] -> None | x :: xs -> Some (xs |> List.fold_left f x)
  in
  reduce ( ++ ) decs
