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
  type expty = { exp : Translate.exp; ty : Types.ty }
  type venv = Env.enventry Symbol.table
  type tenv = Types.ty Symbol.table
  type newEnv = { venv : venv; tenv : tenv }

  let transExp vars tys (exp : Absyn.exp) =
    match exp with
    | Absyn.OpExp { left; oper; right; pos } -> { exp = (); ty = Types.UNIT }
    | Absyn.VarExp (Absyn.SimpleVar (_, _))
    | Absyn.VarExp (Absyn.FieldVar (_, _, _))
    | Absyn.VarExp (Absyn.SubscriptVar (_, _, _)) ->
        { exp = (); ty = Types.UNIT }
    | Absyn.NilExp -> { exp = (); ty = Types.UNIT }
    | Absyn.IntExp value -> { exp = (); ty = Types.INT }
    | Absyn.StringExp (value, _) -> { exp = (); ty = Types.STRING }
    | Absyn.CallExp { func; args; pos } -> { exp = (); ty = Types.UNIT }
    | Absyn.RecordExp { fields; typ; pos } -> { exp = (); ty = Types.UNIT }
    | Absyn.SeqExp exps -> { exp = (); ty = Types.UNIT }
    | Absyn.AssignExp { var; exp; pos } -> { exp = (); ty = Types.UNIT }
    | Absyn.IfExp { test; then'; else'; pos } -> { exp = (); ty = Types.UNIT }
    | Absyn.WhileExp { test; body; pos } -> { exp = (); ty = Types.UNIT }
    | Absyn.ForExp { var; escape; lo; hi; body; pos } ->
        { exp = (); ty = Types.UNIT }
    | Absyn.BreakExp _ -> { exp = (); ty = Types.UNIT }
    | Absyn.LetExp { decs; body; pos } -> { exp = (); ty = Types.UNIT }
    | Absyn.ArrayExp { typ; size; init; pos } -> { exp = (); ty = Types.UNIT }

  let transVar vars tys (var : Absyn.var) =
    match var with
    | Absyn.SimpleVar (_, _) -> { exp = (); ty = Types.UNIT }
    | Absyn.FieldVar (_, _, _) -> { exp = (); ty = Types.UNIT }
    | Absyn.SubscriptVar (_, _, _) -> { exp = (); ty = Types.UNIT }

  let transDec vars tys (dec : Absyn.dec) =
    match dec with
    | Absyn.FunctionDec _ -> { venv = vars; tenv = tys }
    | Absyn.VarDec _ -> { venv = vars; tenv = tys }
    | Absyn.TypeDec _ -> { venv = vars; tenv = tys }

  let transTy tenv (typ : Absyn.ty) =
    match typ with
    | Absyn.NameTy (_, _) -> Types.UNIT
    | Absyn.RecordTy _ -> Types.UNIT
    | Absyn.ArrayTy (_, _) -> Types.UNIT

  (* ignore the result to just type check *)
  let transProg e = ignore @@ transExp Env.base_venv Env.base_tenv e
end
