type level [@@deriving show]
(* not the same as Frame.access *)
type access [@@deriving show]
type newLevelArg = { parent : level; name : Temp.label; formals : bool list }

type exp = 
  Ex of Tree.exp (* expression *)
  | Nx of Tree.stm (* no result *)
  | Cx of (Temp.label * Temp.label -> Tree.stm) (* conditional *)

(* conversion functions --*)

(* need to invent new temporary r and new labels t and f. Then we make a Tree.stm 
that moves the value 1 into r and a conditional jump genstm(t, f) that implements 
the ocnditional. If the conditional is false, then 0 is moved into r; if true 
then execution proceeds at t and the second move is skipped the result of the whole 
thing is just the tmeporary r containing 0 or 1*)
val unEx : exp -> Tree.exp 
val unNx : exp -> Tree.stm
val unCx : exp -> (Temp.label * Temp.label -> Tree.stm) 

val outermost : level
val newLevel : newLevelArg -> level
val formals : level -> access list
val allocLocal : level -> bool -> access


