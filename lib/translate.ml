(*
s i g n a t u r e sig
TRANSLATE =
type level
type access (* not the same as Frame.access *)
v a l o u t e r m o s t : l e v e l
val newlevel : (parent: level, name: Temp. label,
f o r m a l s : bool val formals: level -> access list
v a l a l l o c L o c a l : l e v e l -> b o o l l i s t ) -> - > l e v e l
a c c e s s
e n d
*)

type exp = unit

type level =
  | Level of { parent : level; frame : Frame.frame; unique : unit ref }
  | Outermost
[@@deriving show]

type access = level * Frame.access [@@deriving show]

let outermost = Outermost

let new_level parent name formals =
  let formals_with_link = true :: formals in
  (* Static link always escapes *)
  let frame = Frame.new_frame name formals_with_link in
  Level { parent; frame; unique = ref () }

let formals = function
  | Outermost -> failwith "Outermost level has no formals"
  | Level { frame; parent = _; unique = _ } as level ->
      let frame_formals = Frame.formals frame in
      let without_static_link = List.tl frame_formals in
      (* Remove static link *)
      List.map (fun access -> (level, access)) without_static_link

let alloc_local (escape : bool) = function
  | Outermost -> failwith "Outermost level has no formals"
  | Level { frame; parent = _; unique = _ } as level ->
      let frame_access = Frame.alloc_local frame escape in
      (level, frame_access)
