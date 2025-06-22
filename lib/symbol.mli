type symbol = string * int

val pp_symbol : Format.formatter -> symbol -> unit
val show_symbol : symbol -> string

module H = Hashtbl

exception Symbol

val nextsym : int ref
val sizeHint : int
val hashtable : (string, int) H.t
val symbol : string -> string * int
val name : 'a * 'b -> 'a

type 'a table

val table_to_list : 'a table -> (symbol * 'a) list
val empty : 'a table
val enter : symbol -> 'a -> 'a table -> 'a table
val look : symbol -> 'a table -> 'a option
val show_table : ('a -> string) -> 'a table -> string
