open Symbol

type ty = Types.ty [@@deriving show]

type enventry =
  | VarEntry of { ty : ty; access : Translate.access }
  | FunEntry of {
      level : Translate.level;
      label : Temp.label;
      formals : ty list;
      result : ty;
    }
[@@deriving show]

let base_tenv : ty Symbol.table =
  let base = Symbol.enter (Symbol.empty, Symbol.symbol "int", Types.INT) in
  Symbol.enter (base, Symbol.symbol "string", Types.STRING)

let base_venv level : enventry Symbol.table =
  let open Types in
  let base = Symbol.empty in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "print",
        FunEntry
          {
            level;
            label = Temp.newlabel ();
            formals = [ STRING ];
            result = UNIT;
          } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "flush",
        FunEntry
          { level; label = Temp.newlabel (); formals = []; result = UNIT } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "getchar",
        FunEntry
          { level; label = Temp.newlabel (); formals = []; result = STRING } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "ord",
        FunEntry
          {
            level;
            label = Temp.newlabel ();
            formals = [ STRING ];
            result = INT;
          } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "chr",
        FunEntry
          {
            level;
            label = Temp.newlabel ();
            formals = [ INT ];
            result = STRING;
          } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "size",
        FunEntry
          {
            level;
            label = Temp.newlabel ();
            formals = [ STRING ];
            result = INT;
          } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "substring",
        FunEntry
          {
            level;
            label = Temp.newlabel ();
            formals = [ STRING; INT; INT ];
            result = STRING;
          } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "concat",
        FunEntry
          {
            level;
            label = Temp.newlabel ();
            formals = [ STRING; STRING ];
            result = STRING;
          } )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "not",
        FunEntry
          { level; label = Temp.newlabel (); formals = [ INT ]; result = INT }
      )
  in
  let base =
    Symbol.enter
      ( base,
        Symbol.symbol "exit",
        FunEntry { level; label = Temp.newlabel (); formals = []; result = INT }
      )
  in
  base

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
