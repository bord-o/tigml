type exp = Tree.exp

type level =
  | Level of { parent : level; frame : Frame.frame; unique : unit ref }
  | Outermost
[@@deriving show]

type access = level * Frame.access [@@deriving show]

let global_fragments : Frame.fragment list ref =  ref []

let outermost = Outermost
let outermost_frame = Frame.new_frame (Temp.named_label "main") []

let new_level parent name formals =
  let formals_with_link = true :: formals in
  (* Static link always escapes *)
  let frame = Frame.new_frame name formals_with_link in
  Level { parent; frame; unique = ref () }

let formals = function
  | Outermost -> []
  | Level { frame; parent = _; unique = _ } as level ->
      let frame_formals = Frame.formals frame in
      let without_static_link = List.tl frame_formals in
      (* Remove static link *)
      List.map (fun access -> (level, access)) without_static_link

let alloc_local (escape : bool) = function
  | Outermost ->
      let frame_access = Frame.alloc_local outermost_frame escape in
      (Outermost, frame_access)
  | Level { frame; parent = _; unique = _ } as level ->
      let frame_access = Frame.alloc_local frame escape in
      (level, frame_access)

let new_string s =
      let lab = Temp.new_label() in
      let frag = Frame.String (lab, s) in
      global_fragments := frag :: !global_fragments;
      Tree.Name(lab)

let simple_var (venv ) (tenv ) (access : access) : exp =
  (* Level has a frame and parent leve, access is a reg or temp *)
  let level, frame_access = access in
  match (level, frame_access) with
  | Level l, InFrame n -> Tree.Const 99
  | Level l, InReg temp -> Tree.Const 99
  | Outermost, InFrame n -> Tree.Const 99
  | Outermost, InReg temp -> Tree.Const 99
