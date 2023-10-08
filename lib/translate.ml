open Riscvframe

type level = unit
type access = level * Riscvframe.access
type exp = unit

type newLevelArg = { parent : level; name : Temp.label; formals : bool list }

let outermost = ()
let newLevel x = ()
let formals x = []
let allocLocal l b :access = ((), InFrame 0)
