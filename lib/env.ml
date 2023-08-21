open Symbol

module type ENV = sig
  type access
  type ty

  type enventry =
    | VarEntry of { ty : ty }
    | FunEntry of { formals : ty list; result : ty }

  val base_tenv : ty Symbol.table
  val base_venv : enventry Symbol.table
end

module Env : ENV = struct
  type access = unit
  type ty = Types.ty

  type enventry =
    | VarEntry of { ty : ty }
    | FunEntry of { formals : ty list; result : ty }

  let base_tenv = Symbol.empty
  let base_venv = Symbol.empty
end
