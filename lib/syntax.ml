type unop = OpNeg
type binop = OpPlus | OpMinus | OpTimes | OpDiv

type expr = raw_expr

and raw_expr =
  | ELiteral of int
  | EUnOp of unop * expr
  | EBinOp of expr * binop * expr
  | Nothing

let string_of_expr e =
  let open Printf in
  match e with
  | ELiteral i -> printf "%i\n" i
  | EUnOp (_, _) -> printf "- exp"
  | EBinOp (_, _, _) -> printf "exp,binop, exp2"
  | Nothing -> printf "nothing"
