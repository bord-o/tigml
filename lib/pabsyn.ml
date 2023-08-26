open Printf
open Absyn

let indent_size = 2

let rec string_of_var depth = function
  | SimpleVar (s, _) -> s
  | FieldVar (v, s, _) -> string_of_var (depth + 1) v ^ "." ^ s
  | SubscriptVar (v, e, _) ->
      string_of_var (depth + 1) v ^ "[" ^ string_of_exp (depth + 1) e ^ "]"

and string_of_oper = function
  | PlusOp -> "+"
  | MinusOp -> "-"
  | TimesOp -> "*"
  | DivideOp -> "/"
  | EqOp -> "="
  | NeqOp -> "<>"
  | LtOp -> "<"
  | LeOp -> "<="
  | GtOp -> ">"
  | GeOp -> ">="

and string_of_exp depth = function
  | VarExp v -> indent depth ^ "VarExp(" ^ string_of_var (depth + 1) v ^ ")"
  | NilExp -> indent depth ^ "NilExp"
  | IntExp i -> indent depth ^ "IntExp(" ^ string_of_int i ^ ")"
  | StringExp (s, _) -> indent depth ^ sprintf "StringExp(\"%s\")" s
  | CallExp { func; args; _ } ->
      let args_str =
        String.concat ", " (List.map ( fun s -> "\n" ^ string_of_exp (depth + 1) s) args)
      in
      indent depth ^ sprintf "CallExp(%s(%s))" ( func) args_str
  | OpExp { left; oper; right; _ } ->
      indent depth ^ "OpExp(\n"
      ^ string_of_exp (depth + 1) left
      ^ ",\n"
      ^ indent (depth + 1)
      ^ string_of_oper oper ^ ",\n"
      ^ string_of_exp (depth + 1) right
      ^ "\n" ^ indent depth ^ ")"
  | RecordExp { fields; typ; _ } ->
      indent depth ^ "RecordExp(type=" ^ typ ^ ", fields=\n"
      ^ String.concat ",\n"
          (List.map
             (fun (s, e, _) ->
               indent (depth + 1) ^ s ^ "=" ^ string_of_exp (depth + 1) e)
             fields)
      ^ ")"
  | SeqExp es ->
      indent depth ^ "SeqExp(\n"
      ^ String.concat ",\n"
          (List.map (fun (e, _) -> string_of_exp (depth + 1) e) es)
      ^ "\n" ^ indent depth ^ ")"
  | AssignExp { var; exp; _ } ->
      indent depth ^ "AssignExp(\n"
      ^ string_of_var (depth + 1) var
      ^ " =\n"
      ^ string_of_exp (depth + 1) exp
      ^ "\n" ^ indent depth ^ ")"
  | IfExp { test; then'; else'; _ } ->
      indent depth ^ "IfExp(\n"
      ^ string_of_exp (depth + 1) test
      ^ "\n"
      ^ string_of_exp (depth + 1) then'
      ^ (match else' with
        | Some e -> "\n" ^ string_of_exp (depth + 1) e
        | None -> "")
      ^ "\n" ^ indent depth ^ ")"
  | WhileExp { test; body; _ } ->
      indent depth ^ "WhileExp(\n"
      ^ string_of_exp (depth + 1) test
      ^ "\n"
      ^ string_of_exp (depth + 1) body
      ^ "\n" ^ indent depth ^ ")"
  | ForExp { var; lo; hi; body; _ } ->
      indent depth ^ "ForExp(\n" ^ var ^ " = "
      ^ string_of_exp (depth + 1) lo
      ^ " to "
      ^ string_of_exp (depth + 1) hi
      ^ "\n"
      ^ string_of_exp (depth + 1) body
      ^ "\n" ^ indent depth ^ ")"
  | BreakExp _ -> indent depth ^ "BreakExp"
  | LetExp { decs; body; _ } ->
      indent depth ^ "LetExp(\n"
      ^ String.concat "\n" (List.map (string_of_dec (depth + 1)) decs)
      ^ "\n"
      ^ string_of_exp (depth + 1) body
      ^ "\n" ^ indent depth ^ ")"
  | ArrayExp { typ; size; init; _ } ->
      indent depth ^ "ArrayExp(type=" ^ typ ^ ", size="
      ^ string_of_exp (depth + 1) size
      ^ ", init="
      ^ string_of_exp (depth + 1) init
      ^ ")"

and string_of_field depth { name; typ; _ } =
  indent depth ^ "Field(" ^ name ^ ": " ^ typ ^ ")"

and string_of_dec depth = function
  | FunctionDec funcs ->
      indent depth ^ "FunctionDec(\n"
      ^ String.concat ",\n"
          (List.map (fun f -> string_of_fundec (depth + 1) f) funcs)
      ^ "\n" ^ indent depth ^ ")"
  | VarDec { name; typ; init; _ } ->
      indent depth ^ "VarDec(" ^ name
      ^ (match typ with Some (t, _) -> ": " ^ t | None -> "")
      ^ " = "
      ^ string_of_exp (depth + 1) init
      ^ ")"
  | TypeDec types ->
      indent depth ^ "TypeDec(\n"
      ^ String.concat ",\n"
          (List.map (fun t -> string_of_typedec (depth + 1) t) types)
      ^ "\n" ^ indent depth ^ ")"

and string_of_fundec depth { name; params; result; body; _ } =
  indent depth ^ "Function(" ^ name ^ "("
  ^ String.concat ", " (List.map (string_of_field (depth + 1)) params)
  ^ "): "
  ^ (match result with Some (t, _) -> t | None -> "void")
  ^ " =\n"
  ^ string_of_exp (depth + 1) body

and string_of_typedec depth { name; ty; _ } =
  indent depth ^ "Type(" ^ name ^ " = " ^ string_of_ty (depth + 1) ty ^ ")"

and string_of_ty depth = function
  | NameTy (name, _) -> name
  | RecordTy fields ->
      indent depth ^ "RecordTy {\n"
      ^ String.concat ",\n" (List.map (string_of_field (depth + 1)) fields)
      ^ "\n" ^ indent depth ^ "}"
  | ArrayTy (name, _) -> "ArrayTy(" ^ name ^ ")"

and indent depth = String.make (depth * indent_size) ' '

let print_exp e =
  print_string (string_of_exp 0 e);
  print_newline ()
