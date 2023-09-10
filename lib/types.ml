open Symbol

type unique = unit ref [@@deriving show]

type ty =
  | RECORD of (Symbol.symbol * ty) list * unique
  | NIL
  | INT
  | STRING
  | ARRAY of ty * unique
  | NAME of Symbol.symbol * ty option ref
  | UNIT
[@@deriving show]

let string_of_type (s : ty) =
  match s with
  | RECORD (_, _) -> "RECORD"
  | NIL -> "NIL"
  | INT -> "INT"
  | STRING -> "STRING"
  | ARRAY (_, _) -> "ARRAY"
  | NAME (_, _) -> "NAME"
  | UNIT -> "UNIT"
