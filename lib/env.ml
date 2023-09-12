open Symbol

type access = unit
type ty = Types.ty [@@deriving show]

type enventry =
  | VarEntry of { ty : ty }
  | FunEntry of { formals : ty list; result : ty }
[@@deriving show]

let base_tenv : ty Symbol.table =
  let base = Symbol.enter (Symbol.empty, Symbol.symbol "int", Types.INT) in
  Symbol.enter (base, Symbol.symbol "string", Types.STRING)

let base_venv : enventry Symbol.table = Symbol.empty

let print_tenv (tenv : ty Symbol.table) =
  Symbol.Table.iter
    (fun sym ty ->
      Printf.printf "SYM: %s --> TYPE: %s\n" (show_symbol sym) (show_ty ty))
    tenv

let print_venv (venv : enventry Symbol.table) =
  Symbol.Table.iter
    (fun sym entry ->
      Printf.printf "SYM: %s --> ENTRY: %s\n" (show_symbol sym)
        (show_enventry entry))
    venv
