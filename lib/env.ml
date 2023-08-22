open Symbol

  type access = unit
  type ty = Types.ty

  type enventry =
    | VarEntry of { ty : ty }
    | FunEntry of { formals : ty list; result : ty }

  let base_tenv = Symbol.empty
  let base_venv = Symbol.empty