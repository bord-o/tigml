(*

  val FP : Temp.temp    (* x8/s0 - frame pointer *)
  val SP : Temp.temp    (* x2/sp - stack pointer *) 
  val RV : Temp.temp    (* x10/a0 - return value *)
  val RA : Temp.temp    (* x1/ra - return address *)

  Argument registers: x10-x17 (a0-a7)
  Saved registers: x8-x9, x18-x27 (s0-s11)
  Temp registers: x5-x7, x28-x31 (t0-t6)

*)

let word_size = 8
let fp = Temp.new_temp ()
let sp = Temp.new_temp ()
let rv = Temp.new_temp ()
let ra = Temp.new_temp ()

type access = InFrame of int | InReg of Temp.temp [@@deriving show]

type frame = {
  name : Temp.label;
  formals : access list;
  (* locals : access list ref; *)
  offset : int ref; (* Stack pointer? *)
}
[@@deriving show]

type fragment =
  | String of Temp.label * string
  | Proc of { body : Tree.stm; frame : frame }

(* This is called when a function is entered *)
let new_frame (name : Temp.label) (formals : bool list) =
  let rec allocate_formals offset acc = function
    | [] -> List.rev acc
    | _e :: es ->
        let access = InFrame offset in
        allocate_formals (offset + word_size) (access :: acc) es
  in
  let allocated_formals = allocate_formals 0 [] formals in
  let frame_size = List.length formals * word_size in
  {
    name;
    formals = allocated_formals;
    (* locals = ref []; *)
    offset = ref frame_size;
  }

let name frame = frame.name
let formals frame = frame.formals

let alloc_local frame _escapes =
  let offset = !(frame.offset) in
  frame.offset := offset + word_size;
  let access = InFrame offset in
  access

let exp (a : access) e =
  let open Tree in
  match a with
  | InFrame f -> Mem (Binop (Plus, e, Const f))
  | InReg temp -> Temp temp
