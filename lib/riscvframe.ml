open Tree

type access = InFrame of int | InReg of Temp.temp [@@deriving show]

type frame = {
  name : Temp.label;
  formals : access list;
  locals : access list ref;
}
[@@deriving show]

type framearg = { name : Temp.label; formals : bool list }

let fp = Temp.newtemp () (* frame pointer *)
let wordSize = 32

(* how will the param be seen from in the function *)
(* eg register vs frame and how will we "view shift" *)
let name (f : frame) : Temp.label = "Test"

let newFrame (call : framearg) =
  (* we are only focusing on all escaping formals *)
  let formals_escape = call.formals in
  (* TODO what do i do if this escapes*)
  let formals_access =
    List.map
      (fun escape -> if escape then InFrame 0 else InReg (Temp.newtemp ()))
      formals_escape
  in

  { name = call.name; formals = formals_access; locals = ref [] }

let allocLocal (frame : frame) (escape : bool) =
  (* TODO what do i do if this escapes*)
  let new_access = if escape then InFrame 0 else InReg (Temp.newtemp ()) in
  frame.locals := new_access :: !(frame.locals);
  new_access

let exp (a : access) tree_exp =
  match a with
  | InFrame i -> Mem (Binop (Plus, tree_exp, Const i)) (* need to calc offset *)
  | InReg reg -> Temp reg
(* just the register *)

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
