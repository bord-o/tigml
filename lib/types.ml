type unique = unit ref [@@deriving show]



type ty =
  | RECORD of (Symbol.symbol * ty) list * unique
  | NIL
  | INT
  | STRING
  | ARRAY of ty * unique
  | NAME of Symbol.symbol * ty option ref
      [@printer
        fun fmt (sym, _) ->
          Format.fprintf fmt "NAME(%s)" (Symbol.name sym)]
  | UNIT
[@@deriving show]


let actual_ty start_type =
  let rec actual_ty_helper seen_types current_type =
    match current_type with
    | NAME (sym, { contents = Some real_type }) ->
        if List.exists (fun (s, _) -> compare s sym = 0) seen_types then
          current_type
        else
          actual_ty_helper ((sym, current_type) :: seen_types) real_type
    | t -> t
  in
  actual_ty_helper [] start_type



