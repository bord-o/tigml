type frame
type access = InFrame of int | InReg of Temp.temp
type framearg = { name : unit; formals : bool list }

val name : frame -> Temp.label
val newFrame : framearg -> frame
val formals : frame -> access list
val allocLocal : frame -> bool -> access
