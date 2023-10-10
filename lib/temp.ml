type label = string [@@deriving show]

(* TODO what is this concrete type?*)
type temp = unit [@@deriving show]

module Table = Map.Make (Int)

(* TODO implement newtemp and the rest *)

let newtemp x = ()
let makestring x = "TODO"
let newlabel x = "TODO"
let namedlabel s = "TODO"
