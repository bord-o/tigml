(* [@@@warning "-27"] *)
(* [@@@warning "-26"] *)

open Util
module S = Symbol
module A = Absyn
module T = Types

let resolv = T.actual_ty
let nullable = T.nullable_reference_types_eq
let ty_eq = T.types_equal
let both_ints_or_strings = T.both_ints_or_strings
let is_eq_neq_op = function A.EqOp | A.NeqOp -> true | _ -> false
let ( ==~ ) = ty_eq
let ( =~ ) = fun l r -> ty_eq l r || nullable (resolv l) (resolv r)
let ( <>~ ) = fun l r -> not @@ ty_eq l r
let ( let* ) = Result.bind

(* TODO: finish this *)
let assigned_in _exp' _v = false

let type_of_abstract_type tenv (typ : A.ty) =
  match typ with
  | A.NameTy (s, pos) -> (
      match S.look (S.symbol s) tenv with
      | Some t -> Ok (resolv t)
      | None -> Error (`NameTypeTranslationNotFound (s, pos)))
  | A.ArrayTy (s, pos) -> (
      match S.look (S.symbol s) tenv with
      | Some t -> Ok (T.ARRAY (resolv t, ref ()))
      | None -> Error (`ArrayTypeTranslationNotFound (s, pos)))
  | A.RecordTy fields ->
      let trans_field (f : A.field) =
        match S.look (S.symbol f.typ) tenv with
        | Some t -> Ok (S.symbol f.name, resolv t)
        | None -> Error (`RecordTypeTranslatinoNotFound f.name)
      in

      let* internal_fields = List.map trans_field fields |> sequence_results in
      Ok (T.RECORD (internal_fields, ref ()))

exception BreakCheck of A.pos

(* TODO: This is dumb, write a proper map function over my AST or figure out the ppx_deriving one  *)
let break_check init (e : A.exp) =
  let rec aux in_loop e' =
    match e' with
    | A.BreakExp p -> (
        match in_loop with true -> () | false -> raise (BreakCheck p))
    | A.WhileExp { test; body; _ } ->
        aux in_loop test;
        aux true body
    | A.ForExp { lo; hi; body; _ } ->
        aux in_loop lo;
        aux in_loop hi;
        aux true body
    | A.VarExp _ -> ()
    | A.NilExp -> ()
    | A.IntExp _ -> ()
    | A.StringExp (_, _) -> ()
    | A.CallExp { args; _ } -> args |> List.iter (aux in_loop)
    | A.OpExp { left; right; _ } ->
        aux in_loop left;
        aux in_loop right
    | A.RecordExp { fields; _ } ->
        fields |> List.iter @@ fun (_, e, _) -> aux in_loop e
    | A.ArrayExp { size; init; _ } ->
        aux in_loop size;
        aux in_loop init
    | A.SeqExp es -> es |> List.iter @@ fun (e, _) -> aux in_loop e
    | A.AssignExp { exp; _ } -> aux in_loop exp
    | A.IfExp { test; then'; else'; _ } ->
        aux in_loop test;
        aux in_loop then';
        Option.map (aux in_loop) else' |> ignore
    | A.LetExp { decs; body; _ } -> (
        aux in_loop body;
        decs
        |> List.iter @@ fun (d : A.dec) ->
           match d with
           | A.FunctionDec fdecs ->
               fdecs
               |> List.iter @@ fun ({ body; _ } : A.fundec) -> aux in_loop body
           | A.VarDec { init; _ } -> aux in_loop init
           | A.TypeDec _ -> ())
  in
  aux init e

let rec typecheck (vars : Env.enventry S.table) (types : T.ty S.table)
    (p : A.exp) (level : Translate.level)
    (break_context : Translate.break_context) =
  let checkexp p level break_context =
    typecheck vars types p level break_context
  in

  match p with
  | A.VarExp (A.SimpleVar (name, _)) as z -> (
      let* found_var =
        S.look (S.symbol name) vars
        |> Option.to_result ~none:(`VariableNotFound z)
      in
      match found_var with
      | Env.FunEntry _ -> Error (`ExpectedVariableGotFunction z)
      | Env.VarEntry { access; ty } ->
          let* ir = Translate.simple_var access ty level in
          Ok (ir, ty))
  | A.VarExp (A.FieldVar (var, sym, _)) as z -> (
      let* record_ir, record_type =
        checkexp (A.VarExp var) level break_context
      in
      match resolv record_type with
      | T.RECORD (fields, _r) ->
          let* field_ty =
            fields
            |> List.assoc_opt (S.symbol sym)
            |> Option.to_result ~none:(`RecordFieldDoesntExist z)
          in
          let* ir = Translate.field_var record_ir (S.symbol sym) fields in
          Ok (ir, field_ty)
      | _ -> Error (`CantAccessFieldOfNonRecordVariable z))
  | A.VarExp (A.SubscriptVar (var, exp', _)) as z -> (
      let* array_ir, array_type = checkexp (A.VarExp var) level break_context in
      let* index_ir, index_type = checkexp exp' level break_context in
      match (resolv array_type, resolv index_type) with
      | T.ARRAY (under_type, _r), T.INT ->
          let* ir = Translate.subscript_var array_ir index_ir in
          Ok (ir, under_type)
      | _, T.INT -> Error (`CantAccessSubscriptOfNonArrayVariable z)
      | T.ARRAY _, _ -> Error (`SubscriptMustBeInteger z)
      | _ -> Error (`SubscriptNonArrayAndNonIntegerIndex z))
  | A.NilExp as _z -> Ok (Tree.Const 0, Types.NIL)
  | A.IntExp i as _z -> Ok (Tree.Const i, Types.INT)
  | A.StringExp (s, _) as _z -> Ok (Translate.new_string s, Types.STRING)
  | A.OpExp oper as z ->
      let op = oper.oper in
      let* l_trans, left = checkexp oper.left level break_context in
      let* r_trans, right = checkexp oper.right level break_context in
      let left, right = (resolv left, resolv right) in
      let* ty =
        match (left, op, right) with
        (* Normal operators are normal *)
        | T.INT, A.PlusOp, T.INT -> Ok T.INT
        | T.INT, A.MinusOp, T.INT -> Ok T.INT
        | T.INT, A.TimesOp, T.INT -> Ok T.INT
        | T.INT, A.DivideOp, T.INT -> Ok T.INT
        (* Equality and non-equality have a special case for records but otherwise just ensure matching types *)
        | T.RECORD _, o, T.RECORD _ when is_eq_neq_op o -> Ok T.INT
        | T.RECORD _, o, T.NIL when is_eq_neq_op o -> Ok T.INT
        | T.NIL, o, T.RECORD _ when is_eq_neq_op o -> Ok T.INT
        | l, o, r when l ==~ r && is_eq_neq_op o -> Ok T.INT
        | l, _o, r when l ==~ r -> Ok l
        (* Comparison operators work on ints and strings *)
        | l, A.LtOp, r when both_ints_or_strings (l, r) -> Ok l
        | l, A.LeOp, r when both_ints_or_strings (l, r) -> Ok l
        | l, A.GtOp, r when both_ints_or_strings (l, r) -> Ok l
        | l, A.GeOp, r when both_ints_or_strings (l, r) -> Ok l
        (* And and or are short-circuiting and are handled in the parser *)
        | _ -> Error (`InvalidOperation z)
      in
      let* ir = Translate.operation l_trans r_trans op in
      Ok (ir, ty)
  | A.IfExp { test; then'; else'; pos = _ } as z -> (
      let* test_ir, test_ty = checkexp test level break_context in
      if test_ty <>~ T.INT then Error (`IfExpTestNotAnInteger z)
      else
        let* then_ir, then_ty = checkexp then' level break_context in
        match else' with
        | Some e ->
            let* else_ir, else_ty = checkexp e level break_context in
            if then_ty =~ else_ty then
              let* ir = Translate.if' test_ir then_ir else_ir in
              Ok (ir, then_ty)
            else Error (`IfExpBranchTypesDiffer z)
        | None ->
            if then_ty =~ T.UNIT then
              let* ir = Translate.if' test_ir then_ir (Const 0) in
              Ok (ir, then_ty)
            else Error (`IfWithoutElseBranchMustBeUnitType z))
  | A.CallExp { func; args; pos = _ } as z -> (
      match S.look (S.symbol func) vars with
      | None -> Error (`FunctionNotFound z)
      | Some (VarEntry _) -> Error (`ExpectedFunctionFoundVar z)
      | Some (FunEntry { formals; result; level = dec_level; label }) ->
          let formals_ir = ref [] in
          let rec check_args expected got =
            match (expected, got) with
            | [], [] -> Ok result
            | e :: exps, g :: gots ->
                let* arg_ir, got_type = checkexp g level break_context in
                formals_ir := arg_ir :: !formals_ir;
                if e ==~ got_type then check_args exps gots
                else Error (`FunctionArgumentWrongType z)
            | [], _ | _, [] -> Error (`UnexpectedNumberOfArguments z)
          in
          let* call_ty = check_args formals args in
          let* ir = Translate.call label !formals_ir dec_level level in
          Ok (ir, call_ty))
  | A.SeqExp exps as _z ->
      let* final_ty =
        match List.nth_opt (List.rev exps) 0 with
        | Some (exp, _pos) ->
            let* _, ty = checkexp exp level break_context in
            Ok ty
        | None -> Ok T.UNIT
      in
      let* stms =
        List.map fst exps
        |> List.map (fun e -> checkexp e level break_context)
        |> sequence_results
        |> Result.map (List.map fst)
      in
      let ir = Translate.seq stms in
      Ok (ir, final_ty)
  | A.WhileExp { test; body; pos = _ } as z -> (
      let* test_ir, test_type = checkexp test level break_context in
      let done_label = Temp.new_label () in
      (* Here we calculate the done label before generating the code for while *)
      (* This allows the body to have access to the proper break point *)
      let* body_ir, body_type = checkexp body level (Some done_label) in
      let* ir = Translate.while' test_ir body_ir done_label in
      match (test_type, body_type) with
      | T.INT, T.UNIT -> Ok (ir, T.UNIT)
      | _, T.UNIT -> Error (`WhileTestNotInt z)
      | T.INT, _ -> Error (`WhileBodyNotUnit z)
      | _, _ -> Error (`WhileTestAndBodyWrongType z))
  | A.BreakExp pos as _z ->
      let* ir = Translate.break' break_context pos in
      Ok (ir, T.UNIT)
  | A.ArrayExp { typ; size; init; pos = _ } as z -> (
      let* _, init_ty = checkexp init level break_context in
      let* _, size_ty = checkexp size level break_context in
      let* found_type =
        S.look (S.symbol typ) types
        |> Option.to_result ~none:(`ArrayTypeNotFound z)
      in
      match (size_ty, resolv found_type) with
      | (T.INT, T.ARRAY (item_type, _)) as resolved_types
        when item_type ==~ init_ty ->
          Ok (Tree.Const 99, snd resolved_types)
      | T.INT, _ -> Error (`ArrayNotTypeArray z)
      | _, _ -> Error (`ArraySizeNotInteger z))
  | A.RecordExp { fields; typ; pos = _ } as z -> (
      let* found_type =
        S.look (S.symbol typ) types
        |> Option.to_result ~none:(`RecordTypeNotFound z)
      in
      match resolv found_type with
      | T.RECORD (found_fields, _r) ->
          let rec check_fields = function
            | [], [] -> Ok (Tree.Const 99, found_type)
            | _v, [] -> Error (`WrongNumberOfFields z)
            | [], _v -> Error (`WrongNumberOfFields z)
            | (name', exp', _) :: ls, (r_sym, r_ty) :: rs -> (
                let l_sym = S.symbol name' in
                let* _, l_ty = checkexp exp' level break_context in
                let types_compatible l_ty r_ty = l_ty =~ r_ty in
                match (l_sym = r_sym, types_compatible l_ty r_ty) with
                | true, true -> check_fields (ls, rs)
                | false, true -> Error (`RecordFieldNamesDontMatch z)
                | true, false -> Error (`RecordFieldTypesDontMatch z)
                | false, false -> Error (`RecordFieldNamesAndTypesDontMatch z))
          in
          check_fields (fields, found_fields)
      | _ -> Error (`RecordTypeNotRecord z))
  | A.AssignExp { var; exp; _ } as z -> (
      let* exp_ir, exp_type = checkexp exp level break_context in
      match var with
      | A.SimpleVar (name, _) -> (
          let* found_var =
            S.look (S.symbol name) vars
            |> Option.to_result ~none:(`VariableNotFound z)
          in
          match found_var with
          | Env.FunEntry _ -> Error (`ExpectedVariableGotFunction z)
          | Env.VarEntry { access; ty = var_type } ->
              if
                var_type ==~ exp_type
                || match exp_type with T.NIL -> true | _ -> false
              then
                let* ir = Translate.assign access exp_ir level in
                Ok (ir, T.UNIT)
              else Error (`AssignmentTypesDontmatch z))
      | A.FieldVar (record_var, field_name, _) -> (
          let* record_ir, record_type =
            checkexp (A.VarExp record_var) level break_context
          in
          match resolv record_type with
          | T.RECORD (fields, _) ->
              let* field_type =
                fields
                |> List.assoc_opt (S.symbol field_name)
                |> Option.to_result ~none:(`RecordFieldDoesntExist z)
              in
              if
                field_type ==~ exp_type
                || match exp_type with T.NIL -> true | _ -> false
              then
                let* ir =
                  Translate.assign_field record_ir (S.symbol field_name) fields
                    exp_ir
                in
                Ok (ir, T.UNIT)
              else Error (`AssignmentTypesDontmatch z)
          | _ -> Error (`CantAccessFieldOfNonRecordVariable z))
      | A.SubscriptVar (array_var, index_exp, _) -> (
          let* array_ir, array_type =
            checkexp (A.VarExp array_var) level break_context
          in
          let* index_ir, index_type = checkexp index_exp level break_context in
          match (resolv array_type, resolv index_type) with
          | T.ARRAY (element_type, _), T.INT ->
              if
                element_type ==~ exp_type
                || match exp_type with T.NIL -> true | _ -> false
              then
                let* ir = Translate.assign_subscript array_ir index_ir exp_ir in
                Ok (ir, T.UNIT)
              else Error (`AssignmentTypesDontmatch z)
          | _, T.INT -> Error (`CantAccessSubscriptOfNonArrayVariable z)
          | T.ARRAY _, _ -> Error (`SubscriptMustBeInteger z)
          | _ -> Error (`SubscriptNonArrayAndNonIntegerIndex z)))
  | A.ForExp { var; escape = _; lo; hi; body; _ } as z -> (
      let* _, lo_type = checkexp lo level break_context in
      let* _, hi_type = checkexp hi level break_context in

      let var_access = Translate.alloc_local true level in
      let new_vars =
        S.enter (S.symbol var)
          (Env.VarEntry { access = var_access; ty = T.INT })
          vars
      in
      let done_label = Temp.new_label () in
      let* body_ir, body_type =
        typecheck new_vars types body level (Some done_label)
      in
      let* lo_ir, _ = checkexp lo level break_context in
      let* hi_ir, _ = checkexp hi level break_context in

      match (resolv lo_type, resolv hi_type, resolv body_type) with
      | T.INT, T.INT, T.UNIT when not @@ assigned_in body var ->
          let* ir =
            Translate.for' var_access lo_ir hi_ir body_ir done_label level
          in
          Ok (ir, T.UNIT)
      | T.INT, T.INT, T.UNIT -> Error (`CantReassignForLoopVariable z)
      | _, _, T.UNIT -> Error (`ForLoopIndexesNotIntegers z)
      | _, _, _ -> Error (`ForLoopBodyReturnsValue z))
  | A.LetExp { decs; body; _ } as z ->
      let checkdec vars types = function
        | A.TypeDec tydecs ->
            let* () = T.detect_duplicate_type_names tydecs in

            let add_type_header ty_env tydec =
              let A.{ name; ty = _; _ } = tydec in
              let placeholder = T.NAME (S.symbol name, ref None) in
              S.enter (S.symbol name) placeholder ty_env
            in

            let types_with_headers =
              List.fold_left add_type_header types tydecs
            in

            let resolve_type_definition ty_env tydec =
              let A.{ name; ty; _ } = tydec in
              let* resolved_type = type_of_abstract_type ty_env ty in

              match S.look (S.symbol name) ty_env with
              | Some (T.NAME (_, placeholder_ref)) ->
                  placeholder_ref := Some resolved_type;
                  Ok ()
              | _ -> failwith "Internal error: placeholder not found"
            in

            let* _ =
              tydecs
              |> List.map (resolve_type_definition types_with_headers)
              |> sequence_results
            in
            if T.detect_cycles types_with_headers then
              Error `IllegalCycleInTypeDec
            else Ok (vars, types_with_headers)
        | A.VarDec { name; escape = _; typ; init; pos = _ } ->
            let* _, init_ty = typecheck vars types init level break_context in
            let* var_ty =
              match typ with
              | None when resolv init_ty <>~ T.NIL -> Ok init_ty
              | None -> Error (`CantDeclareNonReferenceVariableNil z)
              | Some (s, pos) -> (
                  match S.look (S.symbol s) types with
                  | None -> Error (`VariableTypeAnnotationNotFound pos)
                  | Some t when t =~ init_ty -> Ok (resolv t)
                  | Some _ ->
                      Error (`VariableTypeAnnotationDoesntMatchExpression z))
            in
            let new_vars =
              S.enter (S.symbol name)
                (Env.VarEntry
                   { access = Translate.alloc_local true level; ty = var_ty })
                vars
            in
            Ok (new_vars, types)
        | A.FunctionDec fundecs ->
            let* () = T.detect_duplicate_func_names fundecs in
            let extract_formals params =
              params
              |> List.map (fun (f : A.field) ->
                     S.look (S.symbol f.typ) types
                     |> Option.to_result ~none:`UnknownFunctionDecArgType)
              |> sequence_results
            in

            let extract_result_type result =
              match result with
              | None -> Ok T.UNIT
              | Some (s, pos) -> (
                  match S.look (S.symbol s) types with
                  | None -> Error (`FunctionResultAnnotationNotFound pos)
                  | Some t -> Ok t)
            in

            let add_function_header vars fundec =
              let A.{ name; params; result; _ } = fundec in
              let escaping_params =
                params |> List.map @@ fun (p : A.field) -> !(p.escape)
              in
              let* formals = extract_formals params in
              let* result_ty = extract_result_type result in
              let sym = S.symbol name in
              let f_level = Translate.new_level level sym escaping_params in
              let fe =
                Env.FunEntry
                  {
                    formals;
                    result = result_ty;
                    label = Temp.named_label fundec.name;
                    level = f_level;
                  }
              in
              Ok (S.enter sym fe vars)
            in

            let* vars_with_headers =
              List.fold_left
                (fun acc_result fundec ->
                  let* acc_vars = acc_result in
                  add_function_header acc_vars fundec)
                (Ok vars) fundecs
            in

            let check_function_body fundec =
              let A.{ name; params; result; body; _ } = fundec in
              let* formals = extract_formals params in
              let* expected_result_ty = extract_result_type result in
              let* fun_entry =
                S.look (S.symbol name) vars_with_headers
                |> Option.to_result ~none:(`FunctionNotFound z)
              in

              let fun_level =
                match fun_entry with
                | Env.FunEntry { level; _ } -> level
                | _ -> failwith "Expected function entry"
              in

              let bound_args =
                List.fold_left2
                  (fun body_vars ty (field : A.field) ->
                    let ve =
                      Env.VarEntry
                        { access = Translate.alloc_local true fun_level; ty }
                    in
                    S.enter (S.symbol field.name) ve body_vars)
                  vars_with_headers formals params
              in

              let* _, actual_body_ty =
                typecheck bound_args types body level break_context
              in
              if ty_eq actual_body_ty expected_result_ty then Ok ()
              else Error (`FunctionTypeAnnotationDoesntMatchExpression z)
            in

            let* _ =
              fundecs |> List.map check_function_body |> sequence_results
            in

            Ok (vars_with_headers, types)
      in

      let rec checkdecs vars types = function
        | [] -> Ok (vars, types)
        | d :: ds ->
            let* new_vars, new_types = checkdec vars types d in
            checkdecs new_vars new_types ds
      in

      let* new_vars, new_types = checkdecs vars types decs in
      let* _, body_type =
        typecheck new_vars new_types body level break_context
      in
      Ok (Tree.Const 99, body_type)

let typecheckProg' (p : Absyn.exp) =
  let vars =
    Symbol.empty
    |> Symbol.enter (Symbol.symbol "print")
         (Env.FunEntry
            {
              formals = [ T.STRING ];
              result = T.UNIT;
              level = Outermost;
              label = Temp.new_label ();
            })
    |> Symbol.enter (Symbol.symbol "getchar")
         (Env.FunEntry
            {
              formals = [];
              result = T.STRING;
              level = Outermost;
              label = Temp.new_label ();
            })
    |> Symbol.enter (Symbol.symbol "ord")
         (Env.FunEntry
            {
              formals = [ T.STRING ];
              result = T.INT;
              level = Outermost;
              label = Temp.new_label ();
            })
    |> Symbol.enter (Symbol.symbol "chr")
         (Env.FunEntry
            {
              formals = [ T.INT ];
              result = T.STRING;
              level = Outermost;
              label = Temp.new_label ();
            })
  in
  let types =
    Symbol.empty
    |> Symbol.enter (Symbol.symbol "int") T.INT
    |> Symbol.enter (Symbol.symbol "string") T.STRING
  in
  let* _typechecked, _type = typecheck vars types p Outermost None in
  Ok ()

exception IDKBro of string

let typecheckProg p =
  break_check false p;
  let res = typecheckProg' p in
  match res with
  | Ok _v -> () (*print_endline "Ok"*)
  | Error e -> raise (IDKBro (Error.show_typecheck_err e))
(* | Error e -> *)
(*     print_endline "error: "; *)
(*     print_endline @@ show_typecheck_err e *)
