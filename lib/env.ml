type access
type ty = Types.ty [@@deriving show]

type enventry =
  | VarEntry of { ty : ty }
  | FunEntry of { formals : ty list; result : ty } [@@deriving show]

type tenv = ty Symbol.table
type venv = enventry Symbol.table

let show_tenv = Symbol.show_table (Types.show_ty) 
let show_venv = Symbol.show_table (show_enventry) 

let base_tenv : ty Symbol.table = Symbol.empty
let base_venv : enventry Symbol.table = Symbol.empty
