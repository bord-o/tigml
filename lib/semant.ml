[@@@warning "-27"]
[@@@warning "-26"]

module S = Symbol
module A = Absyn
module T = Types

let ( let* ) = Result.bind
let ( let$ ) = Option.bind

let sequence_results results =
  let rec aux acc = function
    | [] -> Ok (List.rev acc)
    | Ok x :: xs -> aux (x :: acc) xs
    | Error e :: _ -> Error e
  in
  aux [] results

type typecheck_err = [ `ArrayNotTypeArray of A.exp
 | `ArraySizeNotInteger of A.exp
 | `ArrayTypeNotFound of A.exp
 | `ArrayTypeTranslationNotFound of string * A.pos
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
 | `FunctionResultAnnotationNotFound of A.pos
 | `FunctionTypeAnnotationDoesntMatchExpression of A.pos
 | `IfExpBranchTypesDiffer of A.exp
 | `IfExpTestNotAnInteger of A.exp
 | `InvalidOperation of A.exp
 | `NameTypeTranslationNotFound of string * A.pos
 | `RecordFieldDoesntExist of A.exp
 | `RecordFieldNamesAndTypesDontMatch of A.exp
 | `RecordFieldNamesDontMatch of A.exp
 | `RecordFieldTypesDontMatch of A.exp
 | `RecordTypeNotFound of A.exp
 | `RecordTypeNotRecord of A.exp
 | `RecordTypeTranslatinoNotFound of string
 | `SubscriptMustBeInteger of A.exp
 | `SubscriptNonArrayAndNonIntegerIndex of A.exp
 | `UnexpectedNumberOfArguments of A.exp
 | `UnknownFunctionDecArgType
 | `VariableNotFound of A.exp
 | `VariableTypeAnnotationDoesntMatchExpression of A.pos
 | `VariableTypeAnnotationNotFound of A.pos
 | `WhileBodyNotUnit of A.exp
 | `WhileTestAndBodyWrongType of A.exp
 | `WhileTestNotInt of A.exp
 | `WrongNumberOfFields of A.exp ] [@@deriving show]

(*
  typecheck takes a abstract syntx node, validates its type, and
  then reconstructs it with an annotation for the type
*)
let rec typecheck (vars : Env.enventry S.table) (types : T.ty S.table)
    (p : A.exp) =
  let checkexp = typecheck vars types in
  let is_eq_or_neq = function A.EqOp | A.NeqOp -> true | _ -> false in
  let assigned_in exp' v = false in
  let type_of_abstract_type tenv (typ : A.ty) =
    match typ with
    | A.NameTy (s, pos) -> (
        match S.look (S.symbol s) tenv with
        | Some t -> Ok t
        | None -> Error (`NameTypeTranslationNotFound (s, pos)))
    | A.ArrayTy (s, pos) -> (
        match S.look (S.symbol s) tenv with
        | Some t -> Ok (T.ARRAY (t, ref ()))
        | None -> Error (`ArrayTypeTranslationNotFound (s, pos)))
    | A.RecordTy fields ->
        let trans_field (f : A.field) =
          match S.look (S.symbol f.typ) tenv with
          | Some t -> Ok (S.symbol f.name, t)
          | None -> Error (`RecordTypeTranslatinoNotFound f.name)
        in

        let* internal_fields =
          List.map trans_field fields |> sequence_results
        in
        Ok (T.RECORD (internal_fields, ref ()))
  in

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
      (* print_endline @@ Env.show_tenv types; *)
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
      let checkdec vars types = function
        | A.TypeDec tydecs ->
            print_endline "td";
            let check_typedecs ty_env = function
              | [] -> Ok ty_env
              | (d : A.typedec) :: ds ->
                  let* resolved_type = type_of_abstract_type ty_env d.ty in
                  let new_types =
                    S.enter (S.symbol d.name) resolved_type ty_env
                  in
                  Ok new_types
            in
            let* (new_types : Env.ty Symbol.table) =
              check_typedecs types tydecs
            in
            Ok (vars, new_types)
        | A.VarDec { name; escape; typ; init; pos } ->
          print_endline "vd";
            let* _, init_ty = typecheck vars types init in
            let* var_ty =
              match typ with
              | None -> Ok init_ty
              | Some (s, pos) -> (
                  match S.look (S.symbol s) types with
                  | None -> Error (`VariableTypeAnnotationNotFound pos)
                  | Some t when t <> init_ty ->
                      Error (`VariableTypeAnnotationDoesntMatchExpression pos)
                  | Some t -> Ok t)
            in

            let new_vars =
              S.enter (S.symbol name) (Env.VarEntry { ty = var_ty }) vars
            in
            Ok (new_vars, types)
        | A.FunctionDec fundecs ->
            let check_fundecs var_env = function
              | [] -> Ok var_env
              | A.{ name; params; result; body; _ } :: ds ->
                  let* formals =
                    params
                    |> List.map (fun (f : A.field) ->
                           S.look (S.symbol f.typ) types
                           |> Option.to_result ~none:`UnknownFunctionDecArgType)
                    |> sequence_results
                  in
                  let* _, body_ty = typecheck var_env types body in
                  let* result_ty =
                    match result with
                    | None -> Ok body_ty
                    | Some (s, pos) -> (
                        match S.look (S.symbol s) types with
                        | None -> Error (`FunctionResultAnnotationNotFound pos)
                        | Some t when t <> body_ty->
                            Error
                              (`FunctionTypeAnnotationDoesntMatchExpression pos)
                        | Some t -> Ok t)
                  in

                  let fe = Env.FunEntry { formals; result=result_ty } in
                  let new_vars =
                    S.enter (S.symbol name) fe vars
                  in

                  Ok new_vars
            in
            Ok (vars, types)
      in

      let rec checkdecs vars types = function
        | [] -> Ok (vars, types)
        | d :: ds ->
            let* new_vars, new_types = checkdec vars types d in

            print_endline @@ Env.show_tenv new_types;
            print_endline @@ Env.show_venv new_vars;
            checkdecs new_vars new_types ds
      in

      let* new_vars, new_types = checkdecs vars types decs in
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
  let types = Symbol.empty |> Symbol.enter (Symbol.symbol "int") T.INT |> Symbol.enter (Symbol.symbol "string") T.STRING  in
  let* typechecked, _type = typecheck vars types p in
  Ok ()

let typecheckProg p =
  let res = typecheckProg' p in
  match res with Ok v -> () | Error e -> print_endline @@ show_typecheck_err e
