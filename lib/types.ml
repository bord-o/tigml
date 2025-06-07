type unique = unit ref [@@deriving show]

type ty =
  | RECORD of (Symbol.symbol * ty) list * unique
  | NIL
  | INT
  | STRING
  | ARRAY of ty * unique
  | NAME of Symbol.symbol * ty option ref
      [@printer
        fun fmt (sym, _) -> Format.fprintf fmt "NAME(%s)" (Symbol.name sym)]
  | UNIT
[@@deriving show]

let actual_ty start_type =
  let rec actual_ty_helper seen_types current_type =
    match current_type with
    | NAME (sym, { contents = Some real_type }) ->
        if List.exists (fun (s, _) -> compare s sym = 0) seen_types then
          current_type
        else actual_ty_helper ((sym, current_type) :: seen_types) real_type
    | t -> t
  in
  actual_ty_helper [] start_type

let both_ints_or_strings = function
  | INT, INT | STRING, STRING -> true
  | _ -> false

let nullable_reference_types_eq t1 t2 =
  match (t1, t2) with
  | RECORD _, NIL -> true
  | ARRAY _, NIL -> true
  | NIL, RECORD _ -> true
  | NIL, ARRAY _ -> true
  | _ -> false

let types_equal t1 t2 =
  let t1, t2 = (actual_ty t1, actual_ty t2) in
  match (actual_ty t1, actual_ty t2) with
  | INT, INT -> true
  | STRING, STRING -> true
  | UNIT, UNIT -> true
  | NIL, NIL -> true
  | RECORD (_fields1, unique1), RECORD (_fields2, unique2) -> unique1 == unique2
  | ARRAY (_elem1, unique1), ARRAY (_elem2, unique2) -> unique1 == unique2
  | NAME (sym1, _), NAME (sym2, _) -> compare sym1 sym2 = 0
  | _ -> false
