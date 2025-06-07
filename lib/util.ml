
let sequence_results results =
  let rec aux acc x =
    match x with
    | [] -> Ok (List.rev acc)
    | Ok x :: xs -> aux (x :: acc) xs
    | Error e :: _ -> Error e
  in
  aux [] results
