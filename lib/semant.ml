open Env
open Symbol
open Translate

module type SEMANT = sig
  type expty = { exp : Translate.exp; ty : Types.ty }
  type venv
  type tenv
  type newEnv = { venv : venv; tenv : tenv }

  (* TODO level should be a real type *)
  val transExp : venv -> tenv -> Translate.level -> Absyn.exp -> expty
  val transVar : venv -> tenv -> Translate.level -> Absyn.var -> expty
  val transDec : venv -> tenv -> Translate.level -> Absyn.dec -> newEnv
  val transTy : tenv -> Absyn.ty -> Types.ty
  val transProg : Absyn.exp -> unit

  exception UnexpectedType of int * int
  exception UnboundIdentifier of int
  exception IncorrectNumberOfArguments of int
  exception IncorrectNumberOfFields of int
  exception CantReassignType of int * string
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

  exception UnexpectedType of int * int
  exception UnboundIdentifier of int
  exception IncorrectNumberOfArguments of int
  exception IncorrectNumberOfFields of int
  exception CantReassignType of int * string

  let third t = match t with _, loc, _, _ -> loc

  let check_nil l r =
    match (l, r) with RECORD (_, _), NIL -> true | _, _ -> false

  (* basic type checking function *)
  let check_type (e : expty) (expected : Types.ty) (p : A.pos) =
    if e.ty = expected || check_nil e.ty expected then ()
    else (
      Printf.printf "Expected %s, but found %s\n" (string_of_type expected)
        (string_of_type e.ty);
      raise @@ UnexpectedType (p.pos_lnum, third __POS__))

  let rec transExp vars tys level (exp : A.exp) =
    (* define wrappers for brevity *)
    let trexp = transExp vars tys level in
    let trvar = transVar vars tys level in
    (* define function to find the concrete type of a type *)
    let rec actual_ty = function
      | NAME (_, { contents = Some real_type }) -> actual_ty real_type
      | t -> t
    in

    match exp with
    (* for operation expressions we just type check the left and right *)
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
    | A.OpExp { left; oper = A.EqOp; right; pos } -> (
        (* TODO: implement for arrays and records*)
        try
          check_type (trexp left) INT pos;
          check_type (trexp right) INT pos;
          { exp = (); ty = INT }
        with _ -> (
          match ((trexp left).ty, (trexp right).ty) with
          | RECORD (l, luniq), RECORD (r, runiq) when luniq == runiq ->
              { exp = (); ty = INT }
          | NIL, NIL -> { exp = (); ty = INT }
          | _ -> raise @@ UnexpectedType (pos.pos_lnum, third __POS__)))
    | A.OpExp { left; oper = A.NeqOp; right; pos } -> (
        (* TODO: implement for arrays and records*)
        try
          check_type (trexp left) INT pos;
          check_type (trexp right) INT pos;
          { exp = (); ty = INT }
        with _ -> (
          match ((trexp left).ty, (trexp right).ty) with
          | RECORD (l, luniq), RECORD (r, runiq) when luniq != runiq ->
              { exp = (); ty = INT }
          | NIL, _ -> { exp = (); ty = INT }
          | _, NIL -> { exp = (); ty = INT }
          | _ -> raise @@ UnexpectedType (pos.pos_lnum, third __POS__)))
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
    (* our concrete expressions return their types *)
    | A.NilExp -> { exp = (); ty = NIL }
    | A.IntExp value -> { exp = (); ty = INT }
    | A.StringExp (value, _) -> { exp = (); ty = STRING }
    (* variable expressions can just use the other function *)
    | A.VarExp v -> trvar v
    (* call expressions type check expected arg count and types, and returns the return type of the callee *)
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
                    raise @@ UnexpectedType (pos.pos_lnum, third __POS__)
                  else ())
                formals arg_tys;
              result
        in
        { exp = (); ty = f_return_type }
    (* ccheck record field count and types like a function call *)
    | A.RecordExp { fields; typ; pos } ->
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

            let check_record l r =
              (* "NIL can be a member of any record" *)
              if l = r || r = NIL then ()
              else (
                Printf.printf "record Expected %s, but found %s\n"
                  (string_of_type l) (string_of_type r);
                raise @@ UnexpectedType (pos.pos_lnum, third __POS__))
            in

            (* iterate through the type definitions fields and types,
               and make sure that both the name and type of each field
               correspond to thos in the expression IN ORDER!!! (easier) *)
            List.iter2
              (fun (lsym, ltype) (rsym, rtype, _) ->
                if lsym <> S.symbol rsym then (
                  (* TODO: fix this recursion *)
                  Printf.printf "Expected %s" @@ S.name lsym;
                  raise @@ UnboundIdentifier pos.pos_lnum)
                else ();
                check_record ltype (trexp rtype).ty)
              type_fields fields
        | other ->
            Printf.printf "Expected %s but found %s" "RECORD"
              (string_of_type other);
            raise @@ UnexpectedType (pos.pos_lnum, third __POS__));

        { exp = (); ty = record_type }
    (* to check a seq we just make sure the last is a unit type, everything prior is ignored *)
    | A.SeqExp exps -> (
        (* you could force unit for all seq like last like in ocaml,
           but the language doesnt explicitly say that, so i will just ignore them *)
        match List.nth_opt (List.rev exps) 0 with
        | Some (exp, pos) -> trexp exp
        | None -> { exp = (); ty = UNIT })
    (* to check if, we make sure test is int, then we return the type of the executed branch depending on if the else exists *)
    | A.IfExp { test; then'; else'; pos } -> (
        let then_type = (trexp then').ty in
        let () = check_type (trexp test) INT pos in
        match else' with
        | None -> { exp = (); ty = then_type }
        | Some else' ->
            check_type (trexp else') then_type pos;
            { exp = (); ty = then_type })
    (* just unit for now *)
    | A.BreakExp _ -> { exp = (); ty = UNIT }
    (* just check that the test is int and body is unit*)
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
          (* TODO fix all existing use of varentry to have an access. here we will need to allocLocal DONE *)
          let access = allocLocal level true in
          S.enter (vars, S.symbol var, VarEntry { ty = INT; access })
        in

        (* Check the body of the loop using the new environment.
           We expect it to be of type UNIT *)
        let body_checked = transExp new_vars_env tys level body in
        check_type body_checked UNIT pos;

        (* Ensure that 'var' is not assigned to in 'body'.*)
        if contains_assignment_to body var then failwith "forbiddent assignment";

        (* Return type of the ForExp is UNIT *)
        { exp = (); ty = UNIT }
    (* hande the var with recursion, make sure it is the same type as
       the expression return that type *)
    | A.AssignExp { var; exp; pos } ->
        check_type (trvar var) (trexp exp).ty pos;
        { exp = (); ty = UNIT }
    (* for a let expression, we bind some new envs then type check the body and return the result type *)
    | A.LetExp { decs; body; pos } ->
        (* add to env *)
        let { venv = new_venv; tenv = new_tenv } =
          List.fold_left
            (fun acc dec ->
              print_endline "Current Environment -------";
              print_venv acc.venv;
              print_tenv acc.tenv;
              Printf.printf "Processing Declaration:\n %s\n\n" (A.show_dec dec);
              (* TODO pass level to main functions correctly DONE *)
              transDec acc.venv acc.tenv level dec)
            { venv = vars; tenv = tys }
            decs
        in

        print_endline "Checking body with new environment:";
        print_venv new_venv;
        print_tenv new_tenv;
        let body_type = transExp new_venv new_tenv level body in

        { exp = (); ty = body_type.ty }
    (* for an array, we type check the array itself, the int size and make sure that the init matches the array type *)
    | A.ArrayExp { typ; size; init; pos } ->
        (* Ensure typ is an array type *)
        let array_type =
          match S.look (tys, S.symbol typ) with
          | Some t -> (
              match actual_ty @@ t with
              | Types.ARRAY (real_t, _) -> real_t
              | othertype ->
                  Printf.printf "Type %s is not an array type\n" typ;
                  (* print_endline @@ Types.show_ty othertype; *)
                  raise @@ UnexpectedType (pos.pos_lnum, third __POS__))
          | None ->
              print_endline "Type not found";
              raise @@ UnexpectedType (pos.pos_lnum, third __POS__)
        in
        (* Ensure size is an integer *)
        check_type (transExp vars tys level size) INT pos;
        (* Ensure init type matches the base type of the array *)
        check_type (transExp vars tys level init) array_type pos;

        { exp = (); ty = Types.ARRAY (array_type, ref ()) }

  and transVar vars tys level (var : A.var) =
    let trexp = transExp vars tys level in
    let trvar = transVar vars tys level in

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
                raise @@ UnexpectedType (pos.pos_lnum, third __POS__))
        | _ ->
            print_endline "Expected a record type";
            raise @@ UnexpectedType (pos.pos_lnum, third __POS__))
    | A.SubscriptVar (var, exp, pos) -> (
        let array_type = trvar var in
        let index_type = trexp exp in
        match (array_type.ty, index_type.ty) with
        | ARRAY (elementType, _), INT -> { exp = (); ty = elementType }
        | _, _ ->
            print_endline "Array type or index type mismatch";
            raise @@ UnexpectedType (pos.pos_lnum, third __POS__))

  and transDec vars tys level (dec : A.dec) =
    (* this is where most of our AR code goes ig *)
    match dec with
    (* TODO handle frame creation *)
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

              (* TODO: make a new level here and update the FunEntry with a new level*)
              (* TODO: update FunEntry constructor to take the Temp.label and level of the new frame*)
              let escaping_formals = List.map (fun arg -> true) formals in
              let new_level =
                newLevel
                  (* TODO: formals should map all existing formals to escape*)
                  {
                    parent = level;
                    name = Temp.newlabel ();
                    formals = escaping_formals;
                  }
              in

              (* Update venv with function details *)
              S.enter
                ( venv,
                  S.symbol name,
                  E.FunEntry
                    {
                      level = new_level;
                      label = Temp.newlabel ();
                      formals;
                      result = result_type;
                    } ))
            vars funDecList
        in

        { venv = new_venv; tenv = tys }
    (* TODO handle local creation *)
    | A.VarDec varDec ->
        (* print_endline @@ A.show_exp varDec.init; *)
        let compare_records l r =
          match (l, r) with
          | RECORD (_, luniq), RECORD (_, runiq) when luniq != runiq ->
              raise @@ UnexpectedType (varDec.pos.pos_lnum, third __POS__)
          | _ -> ()
        in
        let check_nil l r =
          match (l, r) with RECORD (_, _), NIL -> true | _, _ -> false
        in

        let init_type = (transExp vars tys level varDec.init).ty in

        (* print_endline @@ show_ty init_type; *)
        let var_type =
          match varDec.typ with
          | Some (ty_name, ty_pos) -> (
              match S.look (tys, S.symbol ty_name) with
              | Some t -> t
              | None -> raise @@ UnboundIdentifier ty_pos.pos_lnum)
          | None ->
              if init_type = NIL then
                raise @@ UnexpectedType (varDec.pos.pos_lnum, third __POS__)
              else init_type
        in
        (* print_endline @@ show_ty var_type; *)
        Printf.printf "\n\nComparing var: \n%s to init: \n%s\n\n"
          (show_ty var_type) (show_ty init_type);
        if var_type <> init_type && (not @@ check_nil var_type init_type) then
          raise @@ UnexpectedType (varDec.pos.pos_lnum, third __POS__);
        compare_records var_type init_type;
        let new_venv =
          (* TODO: make a new local here and update the VarEntry with a new access*)
          (* TODO: update VarEntry constructor to take the new access*)
          (* TODO: right now all variables escape as the book says *)
          let access = Translate.allocLocal level true in
          S.enter
            (vars, S.symbol varDec.name, E.VarEntry { ty = var_type; access })
        in
        { venv = new_venv; tenv = tys }
    | A.TypeDec typeDecList ->
        let recursive_tenv, _ =
          List.fold_left
            (fun (tenv, block_tenv) (typedec : A.typedec) ->
              let name = typedec.A.name in
              (* print_endline name; *)
              (* TODO: this works in generall but needs to be limited to one recursiv block *)
              (match S.look (block_tenv, S.symbol name) with
              | Some entry ->
                  raise @@ CantReassignType (typedec.pos.pos_lnum, name)
              | _ -> ());

              (*keep an extra accumulator for the current block that starts empty*)
              (* this is just to make sure we arent breaking test 38*)
              let new_tenv =
                S.enter (tenv, S.symbol name, NAME (S.symbol name, ref None))
              in
              let new_block_env =
                S.enter (tenv, S.symbol name, NAME (S.symbol name, ref None))
              in
              (new_tenv, new_block_env))
            (tys, Symbol.empty) typeDecList
        in

        E.print_tenv recursive_tenv;
        print_newline ();

        let new_tenv =
          List.fold_left
            (fun tenv (typedec : A.typedec) ->
              let name = typedec.A.name in
              (* print_endline name; *)
              let ty = typedec.A.ty in
              let internal_ty = transTy tenv ty in

              E.print_tenv recursive_tenv;
              print_newline ();

              S.enter (tenv, S.symbol name, internal_ty))
            recursive_tenv typeDecList
        in

        { venv = vars; tenv = new_tenv }

  and transTy tenv (typ : A.ty) =
    match typ with
    | A.NameTy (s, pos) -> (
        match S.look (tenv, S.symbol s) with
        | Some t -> t
        | None -> raise @@ UnboundIdentifier pos.pos_lnum)
    | A.ArrayTy (s, pos) -> (
        match S.look (tenv, S.symbol s) with
        | Some t -> Types.ARRAY (t, ref ())
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
  let transProg e =
    let main_level =
      newLevel
        { parent = Translate.outermost; name = Temp.newlabel (); formals = [] }
    in

    (* we tell the base venv that it is at the main level here per book instruction *)
    ignore @@ transExp (Env.base_venv main_level) Env.base_tenv main_level e
end
