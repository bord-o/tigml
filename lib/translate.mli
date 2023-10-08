type level
(* not the same as Frame.access *)
type access
type newLevelArg = { parent : level; name : Temp.label; formals : bool list }
type exp = unit

val outermost : level
val newLevel : newLevelArg -> level
val formals : level -> access list
val allocLocal : level -> bool -> access
