type label = string
type temp


(*  returns a new temp from inf set  *)
val newtemp : unit -> temp

(* returns a new lable from inf set *)
val makestring : temp -> string
val newlabel : unit -> label

(* returns a new label whose assembly name is 'string' *)
val namedlabel : string -> label
