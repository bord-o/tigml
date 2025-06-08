(*
signature FRAME =
s i g type frame
type access
val newFrame : (name: Temp.label, f o r m a l s : b o o l l i s t ) -› f r a m e
val name : frame -> Temp. label
val formals : frame a c c e s s l i s t
val allocLocal : f r a m e -> b o o l - > a c c e s s
end
*)

let word_size = 8

type access = InFrame of int | InReg of Temp.temp [@@deriving show]

type frame = {
  name : Temp.label;
  formals : access list;
  locals : access list ref;
  offset : int ref; (* Stack pointer? *)
}
[@@deriving show]

(* This is called when a function is entered *)
let new_frame (name : Temp.label) (formals : bool list) =
  let rec allocate_formals offset acc = function
    | [] -> List.rev acc
    | _e :: es ->
        let access = InFrame offset in
        allocate_formals (offset + word_size) (access :: acc) es
  in

  let allocated_formals = allocate_formals 0 [] formals in
  { name; formals = allocated_formals; locals = ref []; offset = ref 0 }

let name frame = frame.name
let formals frame = frame.formals

let alloc_local frame _escapes =
  let offset = !(frame.offset) in
  frame.offset := offset + word_size;
  let access = InFrame offset in
  access
