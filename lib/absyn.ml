open List

type pos = Lexing.position
type symbol = string

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

type var =
  | SimpleVar of symbol * pos
  | FieldVar of var * symbol * pos
  | SubscriptVar of var * exp * pos

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

let rec pad s i = if i = 0 then s else pad ("  " ^ s) (i - 1)

let rec print_var (var : var) (indent : int) =
  let pp s = print_endline (pad s indent) in
  match var with
  | SimpleVar (s, _) -> pp @@ "simple var: " ^ s
  | FieldVar (v, s, _) ->
      pp "field var:";
      print_var v (indent + 1);
      pp s
  | SubscriptVar (v, e, _) ->
      pp "sub var:";
      print_var v (indent + 1);
      print_exp e (indent + 1)

and print_dec (dec : dec) (indent : int) =
  let pp s = print_endline (pad s indent) in

  let print_fdec f indent =
    let {
      name : symbol;
      params : field list;
      result : (symbol * pos) option;
      body : exp;
      pos : pos;
    } =
      f
    in
    pp name;
    iter
      (fun { name : symbol; escape : bool ref; typ : symbol; pos : pos } ->
        pp name;
        pp typ)
      params;
    (match result with Some (s, _) -> pp s | None -> ());
    print_exp body (indent + 1)
  in

  match dec with
  | FunctionDec l -> iter (fun f -> print_fdec f indent) l
  | VarDec _ -> pp "var dec"
  | TypeDec l -> iter (fun fdec -> pp "type dec") l

and print_exp (expression : exp) (indent : int) =
  let pp s = print_endline (pad s indent) in
  let string_of_oper (oper : oper) =
    match oper with
    | PlusOp -> "+"
    | MinusOp -> "-"
    | TimesOp -> "*"
    | DivideOp -> "/"
    | EqOp -> "="
    | NeqOp -> "!="
    | LtOp -> "<"
    | LeOp -> "<="
    | GtOp -> ">"
    | GeOp -> ">="
  in
  match expression with
  | NilExp -> pp "nilexp"
  | IntExp i -> pp @@ Int.to_string i
  | StringExp (s, _) -> pp s
  | SeqExp exps ->
      pp "seq exp";
      iter (fun (exp, pos) -> print_exp exp (indent + 1)) exps
  | CallExp { func : symbol; args : exp list; pos : pos } ->
      pp @@ "function call:" ^ func;
      iter (fun exp -> print_exp exp (indent + 1)) args
  | BreakExp _ -> pp "break"
  | VarExp v -> print_var v indent
  | ArrayExp { typ : symbol; size : exp; init : exp; pos : pos } ->
      pp @@ "Array creation" ^ typ;
      print_exp size (indent + 1);
      print_exp init (indent + 1)
  | OpExp { left : exp; oper : oper; right : exp; pos : pos } ->
      print_exp left (indent + 1);
      pp @@ string_of_oper oper;
      print_exp right (indent + 1)
  | LetExp { decs : dec list; body : exp; pos : pos } ->
      pp "Let exp";
      iter (fun dec -> print_dec dec (indent + 1)) decs;
      print_exp body (indent + 1)
  | RecordExp { fields : (symbol * exp * pos) list; typ : symbol; pos : pos } ->
      pp @@ "record exp: " ^ typ;
      iter
        (fun (s, e, _) ->
          pp s;
          print_exp e (indent + 1))
        fields
  | AssignExp { var : var; exp : exp; pos : pos } ->
      pp "assign exp";
      print_var var (indent + 1);
      print_exp exp (indent + 1)
  | IfExp { test : exp; then' : exp; else' : exp option; pos : pos } ->
      pp "if exp";
      print_exp test (indent + 1);
      print_exp then' (indent + 1);
      print_exp (Option.value else' ~default:NilExp) (indent + 1)
  | WhileExp { test : exp; body : exp; pos : pos } ->
      pp "while exp";
      print_exp test (indent + 1);
      print_exp body (indent + 1)
  | ForExp
      {
        var : symbol;
        escape : bool ref;
        lo : exp;
        hi : exp;
        body : exp;
        pos : pos;
      } ->
      pp "for exp";
      pp var;
      print_exp lo (indent + 1);
      print_exp hi (indent + 1);
      print_exp body (indent + 1)
(* TODO: Make all of these print functions coherent. Need to adjust ordering and finish declaration functions *)
