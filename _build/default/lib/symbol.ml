module type SYMBOL = sig
  type symbol

  val symbol : string -> symbol
  val name : symbol -> string

  type 'a table

  val empty : 'a table
  val enter : 'a table * symbol * 'a -> 'a table
  val look : 'a table * symbol -> 'a option
end

module Symbol : SYMBOL = struct
  type symbol = string * int

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
  let enter (t, k, v) = Table.add k v t
  let look (t, k) = Table.find_opt k t
end
