open Env
open Symbol

module Translate = struct
	type exp = unit
end
module type SEMANT = sig
	type expty = {exp: Translate.exp; ty: Types.ty}
	type venv
	type tenv
	type newEnv = {venv: venv; tenv:tenv}

	val transExp : venv * tenv * Absyn.exp -> expty
	val transVar : venv * tenv * Absyn.var -> expty
	val transDec : venv * tenv * Absyn.dec -> newEnv
	val transTy :  tenv * Absyn.ty -> Types.ty
end

module Semant = struct
	type expty = {exp: Translate.exp; ty: Types.ty}
	type venv = Env.enventry Symbol.table
	type tenv = Types.ty Symbol.table
	type newEnv = {venv: venv; tenv:tenv}

	let transExp v t e = { exp=();  ty=Types.UNIT }
	let transVar v t v = { exp=(); ty=Types.UNIT }
	let transDec  v t d = {venv=v ; tenv=t}
	let transTy t typ = Types.UNIT
	
	(* ignore the result to just type check *)
	let transProg e = ignore @@ transExp Env.base_venv Env.base_tenv e
end
