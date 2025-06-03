type access
type ty = Types.ty

type enventry =
  | VarEntry of { ty : ty }
  | FunEntry of { formals : ty list; result : ty }

let base_tenv : ty Symbol.table = Symbol.empty
let base_venv : enventry Symbol.table = Symbol.empty
