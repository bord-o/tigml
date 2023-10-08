open Absyn

module type FindEscape = sig
  val findEscape : Absyn.exp -> unit
end


(*
module FindEscape = struct
    
  let rec findEscape exp =
    match exp with
    | Absyn.VarExp v -> findEscapeVar v
    | Absyn.IntExp _ -> ()
    | Absyn.StringExp _ -> ()
    | Absyn.CallExp { func; args; pos } ->
        List.iter findEscape args
    | _ -> () (* Add other cases here as needed *)

  and findEscapeVar v =
    match v with
    | Absyn.SimpleVar (s, e) ->
        if e then print_endline ("Escaped " ^ Symbol.name s)
    | Absyn.FieldVar (v, s, e) ->
        findEscapeVar v;
        if e then print_endline ("Escaped " ^ Symbol.name s)
    | Absyn.SubscriptVar (v, e) ->
        findEscapeVar v;
        findEscape e
end
*)
