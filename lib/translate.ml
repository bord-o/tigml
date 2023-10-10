open Frame
open Temp

type level =
  | Level of {
      parent : level;
      name : Temp.label;
      formals : bool list;
      frame : Frame.frame;
    }
  | Outermost
[@@deriving show]

type access = Global | Local of level * Frame.access [@@deriving show]
type exp = unit
type newLevelArg = { parent : level; name : Temp.label; formals : bool list }

let outermost = Outermost

let newLevel (x : newLevelArg) : level =
  (* at the macro level: call this when a function makes a new scope level. creates a new frame and level*)
  Level
    {
      parent = x.parent;
      name = x.name;
      formals = x.formals;
      frame = Frame.newFrame { name = Temp.newlabel (); formals = x.formals };
    }

let formals x = []

let allocLocal level escapes : access =
  (* at the macro level: call this when we declare a varable or array. gets a new access for the local*)
  if level = Outermost then failwith "TODO: cannot allocate at the global level"
  else
    let alloc =
      (* TODO: figure out how frame allocation offsets and registers are chosen *)
      if escapes then Frame.InFrame 0 else Frame.InReg (Temp.newtemp ())
    in
    Local (level, alloc)
