module type Temp = sig
  type label
  type temp

  module type Table

  (*  returns a new temp from inf set  *)
  val newtemp : unit -> temp
  (* returns a new lable from inf set *)
  val newlabel : unit -> label
  (* returns a new label whose assembly name is 'string' *)
  val namedlabel : string -> label
end

module Temp = struct
  type label = unit
  type temp
end

module type Frame = sig
  type frame
  type access
  type framearg = { name : unit; formals : bool list }

  val newFrame : framearg -> frame
  val formals : frame -> Temp.label
  val allocLocal : frame -> bool -> access
end

module Riscvframe : Frame = struct
  type frame = unit
  type access = InFrame of int | InReg of Temp.temp
  type framearg = { name : unit; formals : bool list }

  (* how will the param be seen from in the function *)
  (* eg register vs frame and how will we "view shift" *)
  let newFrame (call : framearg) = ()
  let formals (frame : frame) = ()
  let allocLocal (frame : frame) (escape : bool) = InFrame 0
end

module type FindEscape = sig
  val findEscape : Absyn.exp -> unit
end
