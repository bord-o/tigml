type frame [@@deriving show]
type access = InFrame of int | InReg of Temp.temp [@@deriving show]
type framearg = { name : Temp.label; formals : bool list }

val newFrame : framearg -> frame
val allocLocal : frame -> bool -> access
