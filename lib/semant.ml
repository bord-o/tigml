
let typecheck (p : Absyn.exp) =
  match p with
  | Absyn.VarExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.NilExp as z ->
      (* Concrete Nil returns its type *)
      Ok(z, Types.NIL)
  | Absyn.IntExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.StringExp (_, _) as z -> Error (`UnimplementedTypechecking z)
  | Absyn.CallExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.OpExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.RecordExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.SeqExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.AssignExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.IfExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.WhileExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.ForExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.BreakExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.LetExp _ as z -> Error (`UnimplementedTypechecking z)
  | Absyn.ArrayExp _ as z -> Error (`UnimplementedTypechecking z)

let translate (p : Absyn.exp) =
  match p with
  | Absyn.VarExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.NilExp as z -> Error (`UnimplementedTranslation z)
  | Absyn.IntExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.StringExp (_, _) as z -> Error (`UnimplementedTranslation z)
  | Absyn.CallExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.OpExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.RecordExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.SeqExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.AssignExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.IfExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.WhileExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.ForExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.BreakExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.LetExp _ as z -> Error (`UnimplementedTranslation z)
  | Absyn.ArrayExp _ as z -> Error (`UnimplementedTranslation z)

let transProg' (p : Absyn.exp) =
  let ( let* ) = Result.bind in
  let* (typechecked, _type) = typecheck p in
  let* _translated = translate typechecked in
  Ok ()

let transProg p =
  let res = transProg' p in
  match res with
  | Error (`UnimplementedTypechecking b) ->
      print_endline @@ "unimplemented typechecking branch" ^ Absyn.show_exp b
  | Error (`UnimplementedTranslation b) ->
      print_endline @@ "unimplemented translation branch" ^ Absyn.show_exp b
  | Ok _ -> print_endline "No error in semantic analysis"
