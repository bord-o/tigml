open Env
open Symbol

module Translate = struct
  type exp = unit
end

module type SEMANT = sig
  type expty = { exp : Translate.exp; ty : Types.ty }
  type venv
  type tenv
  type newEnv = { venv : venv; tenv : tenv }

  val transExp : venv -> tenv -> Absyn.exp -> expty
  val transVar : venv -> tenv -> Absyn.var -> expty
  val transDec : venv -> tenv -> Absyn.dec -> newEnv
  val transTy : tenv -> Absyn.ty -> Types.ty
  val transProg : Absyn.exp -> unit
end

module Semant : SEMANT = struct
  open Types
  module A = Absyn
  module S = Symbol
  module E = Env

  type expty = { exp : Translate.exp; ty : Types.ty }
  type venv = Env.enventry Symbol.table
  type tenv = Types.ty Symbol.table
  type newEnv = { venv : venv; tenv : tenv }

  exception UnexpectedType of int
  exception UnboundIdentifier of int
  exception IncorrectNumberOfArguments of int
  exception IncorrectNumberOfFields of int

  (* basic type checking function *)
  let check_type (e : expty) (expected : Types.ty) (p : A.pos) =
    if e.ty = expected then ()
    else (
      Printf.printf "Expected %s, but found %s\n" (string_of_type expected)
        (string_of_type e.ty);
      raise @@ UnexpectedType p.pos_lnum)

  let rec transExp vars tys (exp : A.exp) =
    let trexp = transExp vars tys in
    let trvar = transVar vars tys in
    let actual_ty t = () in

    match exp with
    (* for operation expressions we just type check the left and right TODO: do all of these return int? *)
    | A.OpExp { left; oper = A.PlusOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.MinusOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.TimesOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.DivideOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.EqOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.NeqOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.LtOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.LeOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.GtOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.OpExp { left; oper = A.GeOp; right; pos } ->
        check_type (trexp left) INT pos;
        check_type (trexp right) INT pos;
        { exp = (); ty = INT }
    | A.NilExp -> { exp = (); ty = NIL }
    | A.IntExp value -> { exp = (); ty = INT }
    | A.StringExp (value, _) -> { exp = (); ty = STRING }
    (* variable expressions can just use the other function *)
    | A.VarExp v -> trvar v
    | A.CallExp { func; args; pos } ->
        (* is this checking if the function is in the env?*)
        let arg_tys =
          List.map
            (fun arg_exp -> match trexp arg_exp with { exp; ty } -> ty)
            args
        in
        let f_return_type =
          match S.look (vars, S.symbol func) with
          | Some (VarEntry _) ->
              print_endline "Expected function but got variable";
              raise @@ UnboundIdentifier pos.pos_lnum
          | None -> raise @@ UnboundIdentifier pos.pos_lnum
          | Some (FunEntry { formals; result }) ->
              if List.length formals <> List.length arg_tys then
                raise @@ IncorrectNumberOfArguments pos.pos_lnum
              else ();
              List.iter2
                (fun left_type right_type ->
                  if left_type <> right_type then
                    raise @@ UnexpectedType pos.pos_lnum
                  else ())
                formals arg_tys;
              result
        in
        { exp = (); ty = f_return_type }
    | A.RecordExp { fields; typ; pos } ->
        let checked_fields = [] in
        let record_type : ty =
          match S.look (tys, S.symbol typ) with
          | Some t -> t
          | None -> raise @@ UnboundIdentifier pos.pos_lnum
        in
        (match record_type with
        | RECORD (type_fields, _) ->
            if List.length fields <> List.length type_fields then
              raise @@ IncorrectNumberOfFields pos.pos_lnum
            else ();
            (* iterate through the type definitions fields and types,
               and make sure that both the name and type of each field
               correspond to thos in the expression IN ORDER!!! (easier) *)
            List.iter2
              (fun (lsym, ltype) (rsym, rtype, _) ->
                if lsym <> S.symbol rsym then (
                  Printf.printf "Expected %s" @@ S.name lsym;
                  raise @@ UnboundIdentifier pos.pos_lnum)
                else ();
                check_type (trexp rtype) ltype pos)
              type_fields fields
        | other ->
            Printf.printf "Expected %s but found %s" "RECORD"
              (string_of_type other);
            raise @@ UnexpectedType pos.pos_lnum);

        { exp = (); ty = RECORD (checked_fields, ref ()) }
        (* so this returns a record type of (symbol * ty) list * unique *)
    | A.SeqExp exps ->
        (* you could force unit for all seq like last like in ocaml,
           but the language doesnt explicitly say that, so i will just ignore them *)
        let exp, pos = List.(rev exps |> hd) in
        trexp exp
    | A.IfExp { test; then'; else'; pos } -> (
        let then_type = (trexp then').ty in
        let () = check_type (trexp test) INT pos in
        match else' with
        | None -> { exp = (); ty = then_type }
        | Some else' ->
            check_type (trexp else') then_type pos;
            { exp = (); ty = then_type })
    | A.BreakExp _ -> { exp = (); ty = UNIT }
    | A.WhileExp { test; body; pos } ->
        check_type (trexp test) INT pos;
        check_type (trexp body) UNIT pos;
        { exp = (); ty = UNIT }
        (* hande the var with recursion, make sure it is an int, make sure
           lo and high are ints, return body type*)
    | A.ForExp { var; escape; lo; hi; body; pos } ->
        (* TODO: make this function work *)
        let contains_assignment_to _ _ = false in

        (* Check that 'lo' and 'hi' expressions are of type INT *)
        check_type (trexp lo) INT pos;
        check_type (trexp hi) INT pos;

        (* Temporarily introduce 'var' into the environment with type INT.
           This shadows any outer variable with the same name. *)
        let new_vars_env =
          S.enter (vars, S.symbol var, VarEntry { ty = INT })
        in

        (* Check the body of the loop using the new environment.
           We expect it to be of type UNIT *)
        let body_checked = transExp new_vars_env tys body in
        check_type body_checked UNIT pos;

        (* Ensure that 'var' is not assigned to in 'body'.
           For this purpose, I'm writing a function 'contains_assignment_to'.
           The implementation of this function can be complex depending on the complexity
           of your language. We will write a stub for it now. *)
        (* This is a stub for the 'contains_assignment_to' function.
           You'd need to implement it fully. *)
        if contains_assignment_to body var then failwith "forbiddent assignment";

        (* Return type of the ForExp is UNIT *)
        { exp = (); ty = UNIT }
    | A.AssignExp { var; exp; pos } ->
        (* hande the var with recursion, make sure it is the same type as
           the expression return that type *)
        check_type (trvar var) (trexp exp).ty pos;
        { exp = (); ty = UNIT }
    | A.LetExp { decs; body; pos } ->
        (* add to env *)
        let { venv = new_venv; tenv = new_tenv } =
          List.fold_left
            (fun acc dec -> transDec vars tys dec)
            { venv = vars; tenv = tys }
            decs
        in
        let body_type = transExp new_venv new_tenv body in

        { exp = (); ty = body_type.ty }
    (* recursively handle the delarations to build the environment,
       then evaluate the body, returning its type *)
    | A.ArrayExp { typ; size; init; pos } ->
        (* Ensure typ is an array type *)
        let array_type =
          match S.look (tys, S.symbol typ) with
          | Some (Types.ARRAY (t, _)) -> t
          | _ ->
              Printf.printf "Type %s is not an array type\n" typ;
              raise @@ UnexpectedType pos.pos_lnum
        in
        (* Ensure size is an integer *)
        check_type (transExp vars tys size) INT pos;
        (* Ensure init type matches the base type of the array *)
        check_type (transExp vars tys init) array_type pos;

        { exp = (); ty = Types.ARRAY (array_type, ref ()) }

  and transVar vars tys (var : A.var) =
    let trexp = transExp vars tys in
    let trvar = transVar vars tys in

    match var with
    | A.SimpleVar (sym, pos) ->
        let t1 =
          match Symbol.look (vars, S.symbol sym) with
          | Some (E.VarEntry { ty = t }) -> t
          | Some (E.FunEntry _) ->
              print_endline "Expected a var, found a function";
              raise @@ UnboundIdentifier pos.pos_lnum
          | None -> raise @@ UnboundIdentifier pos.pos_lnum
        in
        { exp = (); ty = t1 }
    | A.FieldVar (var, sym, pos) -> (
        let record_type = trvar var in
        match record_type.ty with
        | RECORD (fields, _) -> (
            match List.assoc_opt (S.symbol sym) fields with
            | Some fieldType -> { exp = (); ty = fieldType }
            | None ->
                print_endline "Field not found in the record type";
                raise @@ UnexpectedType pos.pos_lnum)
        | _ ->
            print_endline "Expected a record type";
            raise @@ UnexpectedType pos.pos_lnum)
    | A.SubscriptVar (var, exp, pos) -> (
        let array_type = trvar var in
        let index_type = trexp exp in
        match (array_type.ty, index_type.ty) with
        | ARRAY (elementType, _), INT -> { exp = (); ty = elementType }
        | _, _ ->
            print_endline "Array type or index type mismatch";
            raise @@ UnexpectedType pos.pos_lnum)

  and transDec vars tys (dec : A.dec) =
    match dec with
    | A.FunctionDec funDecList ->
        let new_venv =
          List.fold_left
            (fun venv (fundec : A.fundec) ->
              let name = fundec.A.name in
              let params = fundec.A.params in
              let result = fundec.A.result in
              let body = fundec.A.body in
              let pos = fundec.A.pos in

              (* Determine formal parameter types from 'params' *)
              let formals =
                List.map
                  (fun { A.name = n; A.typ = ty_name; _ } ->
                    match S.look (tys, S.symbol ty_name) with
                    | Some internal_ty -> internal_ty
                    | None -> raise @@ UnboundIdentifier fundec.A.pos.pos_lnum)
                    (* Used fundec's pos since individual field's pos is not available *)
                  (params : A.field list)
              in

              (* Determine the result type from 'result' *)
              let result_type =
                match result with
                | Some (ty_name, ty_pos) -> (
                    match S.look (tys, S.symbol ty_name) with
                    | Some internal_ty -> internal_ty
                    | None -> raise @@ UnboundIdentifier ty_pos.pos_lnum)
                | None -> UNIT
              in

              (* Update venv with function details *)
              S.enter
                ( venv,
                  S.symbol name,
                  E.FunEntry { formals; result = result_type } ))
            vars funDecList
        in

        { venv = new_venv; tenv = tys }
    | A.VarDec varDec ->
        let init_type = (transExp vars tys varDec.init).ty in
        let var_type =
          match varDec.typ with
          | Some (ty_name, ty_pos) -> (
              match S.look (tys, S.symbol ty_name) with
              | Some t -> t
              | None -> raise @@ UnboundIdentifier ty_pos.pos_lnum)
          | None -> init_type
        in
        if var_type <> init_type then
          raise @@ UnexpectedType varDec.pos.pos_lnum;
        let new_venv =
          S.enter (vars, S.symbol varDec.name, E.VarEntry { ty = var_type })
        in
        { venv = new_venv; tenv = tys }
    | A.TypeDec typeDecList ->
        let new_tenv =
          List.fold_left
            (fun tenv typedec ->
              let name = typedec.A.name in
              let ty = typedec.A.ty in
              let internal_ty = transTy tenv ty in
              S.enter (tenv, S.symbol name, internal_ty))
            tys typeDecList
        in
        { venv = vars; tenv = new_tenv }

  and transTy tenv (typ : A.ty) =
    (* TODO: figure out the actual type function and where it should be used*)
    match typ with
    | A.NameTy (s, pos) -> (
        match S.look (tenv, S.symbol s) with
        | Some t -> t
        | None -> raise @@ UnboundIdentifier pos.pos_lnum)
    | A.ArrayTy (s, pos) -> (
        match S.look (tenv, S.symbol s) with
        | Some t -> t
        | None -> raise @@ UnboundIdentifier pos.pos_lnum)
    | A.RecordTy fields ->
        let trans_field (f : A.field) =
          match S.look (tenv, S.symbol f.typ) with
          | Some t -> (S.symbol f.name, t)
          | None -> raise @@ UnboundIdentifier f.pos.pos_lnum
        in
        let internal_fields = List.map trans_field fields in
        RECORD (internal_fields, ref ())

  (* ignore the result to just type check *)
  let transProg e = ignore @@ transExp Env.base_venv Env.base_tenv e
  (* TODO: refactor to let me pass in test environments
     in order to unit test some of my type checking
     before getting to declarations *)
end
