[@@@warning "-27"]

module S = Symbol
module A = Absyn
module T = Types
open Fun

let ( let* ) = Result.bind
let ( let$ ) = Option.bind

 type typecheck_error = [`ArrayNotTypeArray of A.exp
  | `ArraySizeNotInteger of A.exp
  | `ArrayTypeNotFound of A.exp
  | `AssignmentTypesDontmatch of A.exp
  | `CantAccessFieldOfNonRecordVariable of A.exp
  | `CantAccessSubscriptOfNonArrayVariable of A.exp
  | `CantReassignForLoopVariable of A.exp
  | `ExpectedFunctionFoundVar of A.exp
  | `ExpectedVariableGotFunction of A.exp
  | `ForLoopBodyReturnsValue of A.exp
  | `ForLoopIndexesNotIntegers of A.exp
  | `FunctionArgumentWrongType of A.exp
  | `FunctionNotFound of A.exp
  | `IfExpBranchTypesDiffer of A.exp
  | `IfExpTestNotAnInteger of A.exp
  | `InvalidOperation of A.exp
  | `RecordFieldDoesntExist of A.exp
  | `RecordFieldNamesAndTypesDontMatch of A.exp
  | `RecordFieldNamesDontMatch of A.exp
  | `RecordFieldTypesDontMatch of A.exp
  | `RecordTypeNotFound of A.exp
  | `RecordTypeNotRecord of A.exp
  | `SubscriptMustBeInteger of A.exp
  | `SubscriptNonArrayAndNonIntegerIndex of A.exp
  | `UnexpectedNumberOfArguments of A.exp
  | `VariableNotFound of A.exp
  | `WhileBodyNotUnit of A.exp
  | `WhileTestAndBodyWrongType of A.exp
  | `WhileTestNotInt of A.exp
  | `WrongNumberOfFields of A.exp ] [@@deriving show]


(*
  typecheck takes a abstract syntx node, validates its type, and
  then reconstructs it with an annotation for the type
*)
let rec typecheck (vars : Env.enventry S.table) (types : T.ty S.table)
    (p : A.exp): ((A.exp * T.ty), typecheck_error) result =
  let checkexp = typecheck vars types in
  let is_eq_or_neq = function A.EqOp | A.NeqOp -> true | _ -> false in
  let assigned_in exp' v = false in
  let rec actual_ty = function
    | T.NAME (_, { contents = Some real_type }) -> actual_ty real_type
    | t -> t
  in

  let both_ints_or_strings = function
    | T.INT, T.INT | T.STRING, T.STRING -> true
    | _ -> false
  in
  match p with
  | A.VarExp (A.SimpleVar (name, _)) as z -> (
      (* Variable type is looked up in environment *)
      let* found_var =
        S.look (S.symbol name) vars
        |> Option.to_result ~none:(`VariableNotFound z)
      in
      match found_var with
      | Env.FunEntry _ -> Error (`ExpectedVariableGotFunction z)
      | Env.VarEntry v -> Ok (z, v.ty))
  | A.VarExp (A.FieldVar (var, sym, _)) as z -> (
      let* _, record_type = checkexp (A.VarExp var) in
      match record_type with
      | T.RECORD (fields, r) ->
          let* field_ty =
            fields
            |> List.assoc_opt (S.symbol sym)
            |> Option.to_result ~none:(`RecordFieldDoesntExist z)
          in
          Ok (z, T.INT)
      | _ -> Error (`CantAccessFieldOfNonRecordVariable z))
  | A.VarExp (A.SubscriptVar (var, exp', _)) as z -> (
      let* _, array_type = checkexp (A.VarExp var) in
      let* _, index_type = checkexp exp' in
      match (array_type, index_type) with
      | T.ARRAY (under_type, r), T.INT -> Ok (z, under_type)
      | _, T.INT -> Error (`CantAccessSubscriptOfNonArrayVariable z)
      | T.ARRAY _, _ -> Error (`SubscriptMustBeInteger z)
      | _ -> Error (`SubscriptNonArrayAndNonIntegerIndex z))
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
      | l_type, op, r_type -> Error (`InvalidOperation z))
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
      | Some (VarEntry { ty }) -> Error (`ExpectedFunctionFoundVar z)
      | Some (FunEntry { formals; result }) ->
          let rec check_args expected got =
            match (expected, got) with
            | [], [] -> Ok (z, result)
            | e :: exps, g :: gots ->
                let* _, got_type = checkexp g in
                if e = got_type then check_args exps gots
                else Error (`FunctionArgumentWrongType z)
            | [], _ | _, [] -> Error (`UnexpectedNumberOfArguments z)
          in
          check_args formals args)
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
  | A.BreakExp _ as z -> Ok (z, T.UNIT)
  | A.ArrayExp { typ; size; init; pos } as z -> (
      (* check that the underlying type matches initializer  and that size is an integer (do I need ref?) *)
      let* _, init_ty = checkexp init in
      let* _, size_ty = checkexp size in
      let* found_type =
        S.look (S.symbol typ) types
        |> Option.to_result ~none:(`ArrayTypeNotFound z)
      in
      match (size_ty, actual_ty found_type) with
      | (T.INT, T.ARRAY (item_type, _)) as resolved_types
        when item_type = init_ty ->
          Ok (z, snd resolved_types)
      | T.INT, _ -> Error (`ArrayNotTypeArray z)
      | _, _ -> Error (`ArraySizeNotInteger z))
  | A.RecordExp { fields; typ; pos } as z -> (
      let* found_type =
        S.look (S.symbol typ) types
        |> Option.to_result ~none:(`RecordTypeNotFound z)
      in
      match actual_ty found_type with
      | T.RECORD (found_fields, r) ->
          let rec check_fields = function
            | [], [] -> Ok (z, found_type)
            | _v, [] -> Error (`WrongNumberOfFields z)
            | [], _v -> Error (`WrongNumberOfFields z)
            | (name', exp', _) :: ls, (r_sym, r_ty) :: rs -> (
                let l_sym = S.symbol name' in
                let* _, l_ty = checkexp exp' in
                match (l_sym = r_sym, l_ty = r_ty) with
                | true, true -> check_fields (ls, rs)
                | false, true -> Error (`RecordFieldNamesDontMatch z)
                | true, false -> Error (`RecordFieldTypesDontMatch z)
                | false, false -> Error (`RecordFieldNamesAndTypesDontMatch z))
          in
          check_fields (fields, found_fields)
      | _ -> Error (`RecordTypeNotRecord z))
  | A.AssignExp { var; exp; _ } as z ->
      let* _, var_type = checkexp (A.VarExp var) in
      let* _, exp_type = checkexp exp in
      if var_type = exp_type then Ok (z, T.UNIT)
      else Error (`AssignmentTypesDontmatch z)
  | A.ForExp { var; escape; lo; hi; body; _ } as z -> (
      let* _, lo_type = checkexp lo in
      let* _, hi_type = checkexp hi in

      let new_vars =
        S.enter (S.symbol var) (Env.VarEntry { ty = T.INT }) vars
      in
      let* _, body_type = typecheck new_vars types body in

      match (body_type, lo_type, hi_type) with
      | T.INT, T.INT, T.UNIT when not @@ assigned_in body var -> Ok (z, T.UNIT)
      | T.INT, T.INT, T.UNIT -> Error (`CantReassignForLoopVariable z)
      | _, _, T.UNIT -> Error (`ForLoopIndexesNotIntegers z)
      | _, _, _ -> Error (`ForLoopBodyReturnsValue z))
  | A.LetExp { decs; body; _ } as z ->
      let new_vars, new_types =
        decs
        |> (flip List.fold_left) (vars, types) (fun acc dec ->
               match dec with
               | A.FunctionDec fundecs -> acc
               | A.VarDec { name; escape; typ; init; pos } -> acc
               | A.TypeDec tydecs -> acc)
      in
      let* _, body_type = typecheck new_vars new_types body in
      Ok (z, body_type)

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

let typecheckProg' (p : Absyn.exp) =
  let vars = Symbol.empty in
  let types = Symbol.empty in

  let* typechecked, _type = typecheck vars types p in
  Ok ()

let typecheckProg p =
  let res = typecheckProg' p in
  match res with
  | Ok v -> ()
  | Error e -> print_endline @@ show_typecheck_error e

