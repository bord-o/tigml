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

let ( let* ) = Result.bind

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

let detect_cycles (tys : ty Symbol.table) =
  let all_types = Symbol.table_to_list tys in

  let rec follow_chain visited current_ty =
    match current_ty with
    | NAME (sym, { contents = Some next_ty }) ->
        if List.mem sym visited then true
        else follow_chain (sym :: visited) next_ty
    | RECORD _ | ARRAY _ -> false
    | _ -> false
  in

  List.exists (fun (_sym, ty) -> follow_chain [] ty) all_types

(* *)
let detect_duplicate_type_names (decs : Absyn.typedec list) =
  let rec aux acc = function
    | [] -> Ok ()
    | (d : Absyn.typedec) :: ds ->
        if List.mem d.name acc then Error `DuplicateNamesInRecursiveTypeDec
        else aux (d.name :: acc) ds
  in
  aux [] decs

(* *)
let detect_duplicate_func_names (decs : Absyn.fundec list) =
  let rec aux acc = function
    | [] -> Ok ()
    | (d : Absyn.fundec) :: ds ->
        if List.mem d.name acc then Error `DuplicateNamesInRecursiveTypeDec
        else aux (d.name :: acc) ds
  in
  aux [] decs
