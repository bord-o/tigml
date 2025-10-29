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

module Open = struct
type 'a var =
  | SimpleVar of symbol * pos
  | FieldVar of 'a var * symbol * pos
  | SubscriptVar of 'a var * 'a exp * pos
(* [@@deriving show, map, fold] *)

and 'a exp =
  | VarExp of 'a var
  | NilExp
  | IntExp of int
  | StringExp of string * pos
  | CallExp of { func : symbol; args : 'a exp list; pos : pos }
  | OpExp of { left : 'a exp; oper : oper; right : 'a exp; pos : pos }
  | RecordExp of { fields : (symbol * 'a exp * pos) list; typ : symbol; pos : pos }
  | SeqExp of ('a exp * pos) list
  | AssignExp of { var : 'a var; exp : 'a exp; pos : pos }
  | IfExp of { test : 'a exp; then' : 'a exp; else' : 'a exp option; pos : pos }
  | WhileExp of { test : 'a exp; body : 'a exp; pos : pos }
  | ForExp of {
      var : symbol;
      escape : bool ref;
      lo : 'a exp;
      hi : 'a exp;
      body : 'a exp;
      pos : pos;
    }
  | BreakExp of pos
  | LetExp of { decs : 'a dec list; body : 'a exp; pos : pos }
  | ArrayExp of { typ : symbol; size : 'a exp; init : 'a exp; pos : pos }

and field = { name : symbol; escape : bool ref; typ : symbol; pos : pos }

and 'a fundec = {
  name : symbol;
  params : field list;
  result : (symbol * pos) option;
  body : 'a exp;
  pos : pos;
}

and typedec = { name : symbol; ty : ty; pos : pos }

and 'a dec =
  | FunctionDec of 'a fundec list
  | VarDec of {
      name : symbol;
      escape : bool ref;
      typ : (symbol * pos) option;
      init : 'a exp;
      pos : pos;
    }
  | TypeDec of typedec list

and ty =
  | NameTy of symbol * pos
  | RecordTy of field list
  | ArrayTy of symbol * pos
[@@deriving show, map]

end

type t
type nnn = t Open.exp
