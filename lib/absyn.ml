type pos = Lexing.position
type symbol = string [@@deriving show]

let pp_pos fmt (p : pos) =
  let column = p.pos_cnum - p.pos_bol in
  Format.fprintf fmt "line:%i column:%i" p.pos_lnum column

(* Add this line to make ppx_deriving aware of the printer *)
let show_pos p = Format.asprintf "%a" pp_pos p

type oper =
  | PlusOp
  | MinusOp
  | TimesOp
  | DivideOp
  | EqOp
  | NeqOp
  | LtOp
  | LeOp
  | GtOp
  | GeOp
[@@deriving show, map]

type var =
  | SimpleVar of symbol * pos
  | FieldVar of var * symbol * pos
  | SubscriptVar of var * exp * pos
[@@deriving show, map]

and exp =
  | VarExp of var
  | NilExp
  | IntExp of int
  | StringExp of string * pos
  | CallExp of { func : symbol; args : exp list; pos : pos }
  | OpExp of { left : exp; oper : oper; right : exp; pos : pos }
  | RecordExp of { fields : (symbol * exp * pos) list; typ : symbol; pos : pos }
  | SeqExp of (exp * pos) list
  | AssignExp of { var : var; exp : exp; pos : pos }
  | IfExp of { test : exp; then' : exp; else' : exp option; pos : pos }
  | WhileExp of { test : exp; body : exp; pos : pos }
  | ForExp of {
      var : symbol;
      escape : bool ref;
      lo : exp;
      hi : exp;
      body : exp;
      pos : pos;
    }
  | BreakExp of pos
  | LetExp of { decs : dec list; body : exp; pos : pos }
  | ArrayExp of { typ : symbol; size : exp; init : exp; pos : pos }

and field = { name : symbol; escape : bool ref; typ : symbol; pos : pos }

and fundec = {
  name : symbol;
  params : field list;
  result : (symbol * pos) option;
  body : exp;
  pos : pos;
}

and typedec = { name : symbol; ty : ty; pos : pos }

and dec =
  | FunctionDec of fundec list
  | VarDec of {
      name : symbol;
      escape : bool ref;
      typ : (symbol * pos) option;
      init : exp;
      pos : pos;
    }
  | TypeDec of typedec list

and ty =
  | NameTy of symbol * pos
  | RecordTy of field list
  | ArrayTy of symbol * pos
[@@deriving show]
