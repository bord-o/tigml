(* A temp is something in a register, we don't know which one yet *)
type temp = int [@@deriving show]

let temp_count = ref 0

(* This needs to incrent so that all of our registers are distinct *)
let new_temp () =
  incr temp_count;
  !temp_count

(* A label represents a memory address. Think goto labels *)
type label = Symbol.symbol [@@deriving show]

let label_count = ref 0

(* This needs to increment as well *)
let new_label () =
  incr label_count;
  Symbol.symbol ("L" ^ string_of_int !label_count)

(* This needs to include a ref for distinction *)
let named_label = Symbol.symbol

module Table = struct
  type 'a table = (temp * 'a) list

  let empty = []
  let enter table temp value = (temp, value) :: table

  let look table temp =
    try Some (List.assoc temp table) with Not_found -> None
end
