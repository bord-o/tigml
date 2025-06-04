[@@@warning "-27"]

module S = Symbol
module A = Absyn
module T = Types

let ( let* ) = Result.bind
let ( let$ ) = Option.bind

(*
  typecheck takes a abstract syntx node, validates its type, and
  then reconstructs it with an annotation for the type
*)
let rec typecheck (vars : Env.enventry S.table) (types : Env.enventry S.table)
    (p : A.exp) =
  let checkexp = typecheck vars types in
  let is_eq_or_neq = function A.EqOp | A.NeqOp -> true | _ -> false in
  let both_ints_or_strings = function
    | T.INT, T.INT | T.STRING, T.STRING -> true
    | _ -> false
  in
  match p with
  | A.VarExp (A.SimpleVar (name, pos)) as z -> (
      (* Variable type is looked up in environment *)
      match vars |> S.look @@ S.symbol name with
      | Some (Env.VarEntry v) -> Ok (z, v.ty)
      | Some (Env.FunEntry f) ->
          Error (`ExpectedVariableFoundFunction (name, pos))
      | None -> Error (`UnboundVariable name))
  | A.VarExp v as z -> Error (`UnimplementedTypechecking z)
  | A.NilExp as z ->
      (* Concrete Nil returns its type *)
      Ok (z, Types.NIL)
  | A.IntExp _ as z -> Ok (z, Types.INT)
  | A.StringExp (_, _) as z -> Ok (z, Types.STRING)
  | A.OpExp oper as z -> (
      let op = oper.oper in
      let* _, left = checkexp oper.left in
      let* _, right = checkexp oper.right in
      match (left, op, right) with
      (* Normal operators are normal *)
      | T.INT, A.PlusOp, T.INT -> Ok (z, T.INT)
      | T.INT, A.MinusOp, T.INT -> Ok (z, T.INT)
      | T.INT, A.TimesOp, T.INT -> Ok (z, T.INT)
      | T.INT, A.DivideOp, T.INT -> Ok (z, T.INT)
      (* Equality and non-equality have a special case for records but otherwise just ensure matching types *)
      | T.RECORD _, o, T.RECORD _ when is_eq_or_neq o -> Ok (z, T.INT)
      | T.RECORD _, o, T.NIL when is_eq_or_neq o -> Ok (z, T.INT)
      | T.NIL, o, T.RECORD _ when is_eq_or_neq o -> Ok (z, T.INT)
      | l, o, r when l = r -> Ok (z, l)
      (* Comparison operators work on ints and strings *)
      | l, A.LtOp, r when both_ints_or_strings (l, r) -> Ok (z, l)
      | l, A.LeOp, r when both_ints_or_strings (l, r) -> Ok (z, l)
      | l, A.GtOp, r when both_ints_or_strings (l, r) -> Ok (z, l)
      | l, A.GeOp, r when both_ints_or_strings (l, r) -> Ok (z, l)
      (* And and or are short-circuiting and are handled in the parser *)
      | (l_type, op, r_type) as e -> Error (`InvalidOperation e))
  | A.IfExp { test; then'; else'; pos } as z -> (
      let* _, test_ty = checkexp test in
      if test_ty <> T.INT then Error (`IfExpTestNotAnInteger z)
      else
        let* _, then_ty = checkexp then' in
        match else' with
        | Some e ->
            let* _, else_ty = checkexp e in
            if then_ty <> else_ty then Error (`IfExpBranchTypesDiffer z)
            else Ok (z, then_ty)
        | None -> Ok (z, then_ty))
  | A.CallExp { func; args; pos } as z -> (
      (* For a funciton call, check that provided arguments match expected types, and return result type if so *)
      match S.look (S.symbol func) vars with
      | None -> Error (`FunctionNotFound z)
      | Some (VarEntry { ty }) -> Error (`ExpectedFunctionFoundVar (z, ty))
      | Some (FunEntry { formals; result }) ->
          let rec check_args expected got =
            match (expected, got) with
            | [], [] -> Ok (z, result)
            | e :: exps, g :: gots ->
                let* _, got_type = checkexp g in
                if e = got_type then check_args exps gots
                else Error (`FunctionArgumentWrongType z)
            | [], _ | _, [] -> Error `UnexpectedNumberOfArguments
          in
          check_args formals args)
  | A.RecordExp _ as z -> Error (`UnimplementedTypechecking z)
  | A.SeqExp exps as z -> (
      (* A sequence's type is the last type in the list, or unit if it is empty *)
      match List.nth_opt (List.rev exps) 0 with
      | Some (exp, pos) ->
          let* _, ty = checkexp exp in
          Ok (z, ty)
      | None -> Ok (z, T.UNIT))
  | A.WhileExp { test; body; pos } as z -> (
      let* _, test_type = checkexp test in
      let* _, body_type = checkexp body in
      match (test_type, body_type) with
      | T.INT, T.UNIT -> Ok (z, T.UNIT)
      | _, T.UNIT -> Error (`WhileTestNotInt z)
      | T.INT, _ -> Error (`WhileBodyNotUnit z)
      | _, _ -> Error (`WhileTestAndBodyWrongType z))
  | A.AssignExp _ as z -> Error (`UnimplementedTypechecking z)
  | A.ForExp _ as z -> Error (`UnimplementedTypechecking z)
  | A.BreakExp _ as z -> Error (`UnimplementedTypechecking z)
  | A.LetExp _ as z -> Error (`UnimplementedTypechecking z)
  | A.ArrayExp _ as z -> Error (`UnimplementedTypechecking z)

(*
  translate takes a type annotated syntax node and generates
  intermediate code
*)
let translate vars types (p : Absyn.exp) =
  match p with
  | Absyn.VarExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.NilExp as z -> Error (`UnimplementedTranslation z)
  | Absyn.IntExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.StringExp (_, _) as z -> Error (`UnimplementedTranslation z)
  | Absyn.CallExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.OpExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.RecordExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.SeqExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.AssignExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.IfExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.WhileExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.ForExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.BreakExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.LetExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.ArrayExp _ as z -> Error (`UnimplementedTranslation z)

let transProg' (p : Absyn.exp) =
  let ( let* ) = Result.bind in
  let vars = Symbol.empty in
  let types = Symbol.empty in

  let* typechecked, _type = typecheck vars types p in
  let* _translated = translate vars types typechecked in
  Ok ()

let transProg p =
  let res = transProg' p in
  match res with
  | Error (`UnimplementedTypechecking b) ->
      print_endline @@ "unimplemented typechecking branch" ^ Absyn.show_exp b
  | Error (`UnimplementedTranslation b) ->
      print_endline @@ "unimplemented translation branch" ^ Absyn.show_exp b
  | Ok _ -> print_endline "No error in semantic analysis"
  | _ -> print_endline "Handle this error you fuck"
