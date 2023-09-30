

module Temp = Riscvframe.Temp

module type Translate = sig
  type level
  type access (* not the same as Frame.access *)
  type newLevelArg = { parent : level; name : Temp.label; formals : bool list }

  val outermost : level
  val newLevel : newLevelArg -> level
  val formals : level -> access list
  val allocLocal : level -> bool -> access
end

module Translate = struct
  type level  = unit
  type access = level * Riscvframe.Riscvframe.access
  type exp = unit
end
