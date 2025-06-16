type exp =
  | Const of int
  | Name of Temp.label (* like an assembly label *)
  | Temp of Temp.temp
  | Binop of binop * exp * exp
  | Mem of exp (* wordSize bytes of memory starting at the arg address *)
  | Call of exp * exp list
  | ESeq of stm * exp

and stm =
  | Move of exp * exp
  | Exp of exp
  | Jump of exp * Temp.label list
  | CJump of relop * exp * exp * Temp.label * Temp.label
  | Seq of stm * stm
  | Label of Temp.label

and binop =
  | Plus
  | Minus
  | Mul
  | Div
  | And
  | Or
  | LShift
  | RShift
  | ARShift
  | XOr

and relop = EQ | NE | LT | GT | LE | GE | ULT | ULE | UGT | UGE
