type frame [@@deriving show]
type access = InFrame of int | InReg of Temp.temp [@@deriving show]
type framearg = { name : Temp.label; formals : bool list }

val fp : Temp.temp (* frame pointer *)
val wordSize: int (* word size for proc *)
val exp: access -> Tree.exp -> Tree.exp

val newFrame : framearg -> frame
val allocLocal : frame -> bool -> access
