open Temp

type frame = unit
type access = InFrame of int | InReg of Temp.temp
type framearg = { name : unit; formals : bool list }

(* how will the param be seen from in the function *)
(* eg register vs frame and how will we "view shift" *)
let name (f: frame) : Temp.label =  "Test"
let newFrame (call : framearg) = ()
let formals (frame : frame) = []
let allocLocal (frame : frame) (escape : bool) = InFrame 0

(*
  A variable escapes if 
      - it is passed by reference 

        'function(x)' (x escapes if it is a pointer)

      - its address is taken 

        'function(x) {
          some_global_variable = &x (x escapes here)
          return;
        }

      - it is accessed from a nested function

        'function(x) {
          void nested(y) {
            return x + y; (x escapes here)
            ( here the nested function would get a pointer to the stack frame of the containing function "static link")
          }
        }

 *)
