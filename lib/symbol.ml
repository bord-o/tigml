type symbol = string * int [@@deriving show]

module H = Hashtbl

exception Symbol

let nextsym = ref 0
let sizeHint = 128
let hashtable : (string, int) H.t = H.create sizeHint

let symbol name =
  match H.find_opt hashtable name with
  | Some i -> (name, i)
  | None ->
      let i = !nextsym in
      nextsym := i + 1;
      H.add hashtable name i;
      (name, i)

let name (s, _) = s

module Table = Map.Make (struct
  type t = symbol

  let compare (_, x) (_, y) = Stdlib.compare x y
end)

type 'a table = 'a Table.t

let empty = Table.empty
let enter k v t = Table.add k v t
let look k t = Table.find_opt k t

(* printing *)
let table_to_list table = Table.bindings table

let pp_table pp_val fmt table =
  let assoc_list = table_to_list table in
  Format.fprintf fmt "@[<v 0>";
  List.iter (fun (key, value) ->
    Format.fprintf fmt "%a: %a@," pp_symbol key pp_val value
  ) assoc_list;
  Format.fprintf fmt "@]"

let show_table show_val table =
  Format.asprintf "%a" (pp_table (fun fmt v -> Format.pp_print_string fmt (show_val v))) table
