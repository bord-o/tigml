type label = string [@@deriving show]
type temp = int [@@deriving show]

module Table = Map.Make (struct
  type t = temp

  let compare = compare
end)

(* TODO implement newtemp and the rest *)
let temps = ref (-1)
let labels = ref 99

let newtemp x =
  temps := !temps + 1;
  !temps

let newlabel x =
  labels := !labels + 1;
  "l" ^ string_of_int !labels

let namedlabel s = s
let makestring temp = "temp: " ^ string_of_int temp
