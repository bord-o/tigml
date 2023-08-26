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
    match e.ty with
    | INT when expected = INT -> ()
    | STRING when expected = STRING -> ()
    | NIL when expected = NIL -> ()
    | RECORD (a, b) when expected = RECORD (a, b) -> ()
    | ARRAY (a, b) when expected = ARRAY (a, b) -> ()
    | NAME (a, b) when expected = NAME (a, b) -> ()
    | UNIT when expected = UNIT -> ()
    | t ->
        Printf.printf "Expected %s, but found %s\n" (string_of_type expected)
          (string_of_type t);
        raise @@ UnexpectedType p.pos_lnum

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
    | A.VarExp (A.SimpleVar (sym, pos)) ->
        let t1 =
          match Symbol.look (vars, S.symbol sym) with
          | Some (E.VarEntry { ty = t }) -> t
          | Some (E.FunEntry _) ->
              print_endline "Expected a var, found a function";
              raise @@ UnboundIdentifier pos.pos_lnum
          | None -> raise @@ UnboundIdentifier pos.pos_lnum
        in
        { exp = (); ty = t1 }
    (*has a var, should be handled by the other function *)
    (* var.sym *)
    | A.VarExp (A.FieldVar (var, sym, _)) ->
        let record = trvar var in
        (* TODO: this is perplexing to me, because of nested fields/arrays, need to come back *)
        { exp = (); ty = UNIT }
    (* the var in this needs to be resolved to a record type to pass *)
    (* essentially we seperately check that var is a record, and then return the type of sym as a field of that record*)
    (* var[exp]*)
    | A.VarExp (A.SubscriptVar (var, exp, _)) ->
        let array = trvar var in
        { exp = (); ty = UNIT }
        (* the var in this needs to be resolved to an array type to ass*)
    | A.CallExp { func; args; pos } ->
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

        match else' with
        | None -> (
            match then_type with
            | INT -> { exp = (); ty = then_type }
            | _ ->
                Printf.printf "test should be an integer expression";
                raise @@ UnexpectedType pos.pos_lnum)
        | Some e ->
            let else_type = (trexp e).ty in

            let _ =
              if then_type <> else_type then (
                Printf.printf "Expected %s but got %s"
                  (string_of_type then_type) (string_of_type else_type);
                raise @@ UnexpectedType pos.pos_lnum)
              else ()
            in
            { exp = (); ty = then_type })
    | A.BreakExp _ -> { exp = (); ty = UNIT }
    | A.WhileExp { test; body; pos } ->
        (match (trexp test).ty with
        | INT -> ()
        | _ ->
            Printf.printf "test should be an integer expression";
            raise @@ UnexpectedType pos.pos_lnum);
        { exp = (); ty = (trexp body).ty }
    | A.ForExp { var; escape; lo; hi; body; pos } -> { exp = (); ty = UNIT }
    | A.AssignExp { var; exp; pos } -> { exp = (); ty = UNIT }
    | A.LetExp { decs; body; pos } -> { exp = (); ty = UNIT }
    | A.ArrayExp { typ; size; init; pos } -> { exp = (); ty = UNIT }

  and transVar vars tys (var : A.var) =
    match var with
    | A.SimpleVar (_, _) -> { exp = (); ty = UNIT }
    | A.FieldVar (_, _, _) -> { exp = (); ty = UNIT }
    | A.SubscriptVar (_, _, _) -> { exp = (); ty = UNIT }

  and transDec vars tys (dec : A.dec) =
    match dec with
    | A.FunctionDec _ -> { venv = vars; tenv = tys }
    | A.VarDec _ -> { venv = vars; tenv = tys }
    | A.TypeDec _ -> { venv = vars; tenv = tys }

  and transTy tenv (typ : A.ty) =
    match typ with
    | A.NameTy (_, _) -> UNIT
    | A.RecordTy _ -> UNIT
    | A.ArrayTy (_, _) -> UNIT

  (* ignore the result to just type check *)
  let transProg e = ignore @@ transExp Env.base_venv Env.base_tenv e
  (* TODO: refactor to let me pass in test environments
     in order to unit test some of my type checking
     before getting to declarations *)
end
