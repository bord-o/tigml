module A = Absyn

let find_escape (e : A.exp) =
  let rec aux (env : (int * bool ref) list) (depth : int) e' =
    match e' with
    | A.BreakExp _ -> ()
    | A.WhileExp { test; body; _ } ->
        aux env depth test;
        aux env depth body
    | A.ForExp { lo; hi; body; _ } ->
        aux env depth lo;
        aux env depth hi;
        aux env depth body
    | A.VarExp v -> (
        match v with
        | Absyn.SimpleVar (_, _) -> ()
        | Absyn.FieldVar (_, _, _) -> ()
        | Absyn.SubscriptVar (_, _, _) -> ())
    | A.NilExp -> ()
    | A.IntExp _ -> ()
    | A.StringExp (_, _) -> ()
    | A.CallExp { args; _ } -> args |> List.iter (aux env depth)
    | A.OpExp { left; right; _ } ->
        aux env depth left;
        aux env depth right
    | A.RecordExp { fields; _ } ->
        fields |> List.iter @@ fun (_, e, _) -> aux env depth e
    | A.ArrayExp { size; init; _ } ->
        aux env depth size;
        aux env depth init
    | A.SeqExp es -> es |> List.iter @@ fun (e, _) -> aux env depth e
    | A.AssignExp { exp; _ } -> aux env depth exp
    | A.IfExp { test; then'; else'; _ } ->
        aux env depth test;
        aux env depth then';
        Option.map (aux env depth) else' |> ignore
    | A.LetExp { decs; body; _ } -> (
        aux env depth body;
        decs
        |> List.iter @@ fun (d : A.dec) ->
           match d with
           | A.FunctionDec fdecs ->
               fdecs
               |> List.iter @@ fun ({ body; _ } : A.fundec) ->
                  aux env depth body
           | A.VarDec { init; _ } -> aux env depth init
           | A.TypeDec _ -> ())
  in
  aux [] 0 e
