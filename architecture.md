# Tiger Compiler Architecture & IR Generation

## Overview

This document provides detailed technical guidance for implementing IR generation in the Tiger compiler, covering stack management, static link handling, and the low-level semantics from Appel's "Modern Compiler Implementation" chapters 1-7.

## Stack Frame Architecture

### Basic Stack Layout

Tiger uses a traditional stack-based calling convention where each function call creates a new stack frame:

```
Higher Memory Addresses
┌─────────────────────┐
│  Caller's Frame     │
├─────────────────────┤
│  Return Address     │  ← Pushed by CALL instruction
├─────────────────────┤
│  Static Link        │  ← Points to lexically enclosing frame
├─────────────────────┤
│  Function Args      │  ← Arguments passed to callee
├─────────────────────┤
│  Local Variables    │  ← Space for locals (grows downward)
├─────────────────────┤
│  Temporary Values   │  ← Spilled registers, etc.
└─────────────────────┘  ← Stack Pointer (SP)
Lower Memory Addresses
```

### Frame Management in Your Implementation

**Frame Structure (`frame.ml:22-28`)**:
```ocaml
type frame = {
  name : Temp.label;     (* Function name/label *)
  formals : access list; (* How to access each parameter *)
  offset : int ref;      (* Current stack offset for locals *)
}
```

**Access Types (`frame.ml:20`)**:
- `InFrame of int`: Variable stored on stack at offset from frame pointer
- `InReg of Temp.temp`: Variable stored in a register (temporary)

### Stack Space Allocation

**Word Size**: Your implementation uses 8-byte words (`frame.ml:14`)

**Parameter Allocation (`frame.ml:35-49`)**:
- All parameters are currently allocated `InFrame` (on stack)
- Static link is automatically added as first parameter
- Frame offset tracks total space used

**Local Variable Allocation (`frame.ml:54-58`)**:
- `alloc_local` grows the frame by one word size
- Always allocates `InFrame` (no register allocation yet)
- Offset increases monotonically

## Static Links & Nested Scopes

### The Static Link Concept

Static links enable access to variables in lexically enclosing scopes. Each frame contains a pointer to the frame of its lexically enclosing function.

```
function outer(x: int): int =
  let var y := 10
      function inner(z: int): int = 
        x + y + z  (* Needs access to outer's x and y *)
  in inner(5)
  end
```

### Static Link Chain Traversal

Your `traverse_static_links` function (`translate.ml:152-169`) implements this:

1. **Same Level**: Variable is in current frame, use frame pointer directly
2. **Different Level**: Follow static link chain up to declaration level
3. **Chain Walking**: Each step follows one static link to parent frame

**Key Implementation Details**:
- Static link is always the first formal parameter
- It's always stored `InFrame` (never in register)
- Each traversal step: `Mem(Binop(Plus, current_fp, static_link_offset))`

### Level Management (`translate.ml:7-10`)

```ocaml
type level =
  | Level of { parent : level; frame : Frame.frame; unique : unit ref }
  | Outermost
```

- **Outermost**: Top-level/global scope
- **Level**: Nested function scope with parent pointer
- **Unique ref**: Ensures level identity (for equality testing)

## IR Tree Structure

### Expression Types (`tree.ml:1-8`)

- `Const of int`: Integer constants
- `Name of label`: Assembly labels (function names, string literals)
- `Temp of temp`: Register/temporary variable
- `Binop`: Binary operations (arithmetic, logical)
- `Mem of exp`: Memory access (load word from address)
- `Call of exp * exp list`: Function calls
- `ESeq of stm * exp`: Statement followed by expression

### Statement Types (`tree.ml:10-16`)

- `Move of exp * exp`: Assignment (destination, source)
- `Exp of exp`: Expression evaluated for side effects
- `Jump`: Unconditional jump to label
- `CJump`: Conditional jump (comparison, true_label, false_label)
- `Seq of stm * stm`: Sequential composition
- `Label`: Assembly label definition

## Key IR Generation Patterns

### 1. Variable Access

**Local Variables** (`translate.ml:176-177`):
```ocaml
InFrame offset when same_level -> 
  Mem(Binop(Plus, Temp(Frame.fp), Const(offset)))
```

**Non-local Variables** (`translate.ml:178-179`):
```ocaml
InFrame offset when different_level ->
  traverse_static_links ~dec_level ~use_level fp
```

### 2. Function Calls (`translate.ml:196-201`)

Static link calculation is crucial:
- **Callee Level = Outermost**: Static link points to outermost frame
- **Callee Level = Nested**: Static link points to callee's parent level

### 3. Conditional Expressions (`translate.ml:116-130`)

Tiger's approach using temporary results:
```ocaml
let result = new_temp() in
ESeq(
  CJump(NE, test, Const(0), true_label, false_label) ++
  Label(true_label) ++ Move(Temp(result), then_exp) ++
  Jump(done_label) ++
  Label(false_label) ++ Move(Temp(result), else_exp) ++
  Label(done_label),
  Temp(result)
)
```

## Tiger Language Simplifications

### 1. **No Register Allocation Yet**
- All variables allocated on stack (`InFrame`)
- Registers will be allocated in later phases

### 2. **Simple Calling Convention**
- All arguments passed on stack
- Static link always first parameter
- Return value in designated register (`rv`)

### 3. **Fixed Frame Layout**
- Predictable stack offsets
- No optimization for parameter passing
- Escape analysis determines stack vs register later

### 4. **No Advanced Optimizations**
- No leaf function optimizations
- No tail call optimization
- Static link always allocated even if unused

## Current Implementation Status

### ✅ Completed
- Basic frame management and stack allocation
- Static link infrastructure and traversal
- Level-based scope representation
- **Complete variable access** with static link traversal for all scoping levels
- Basic arithmetic and comparison operations
- Conditional expressions (if-then-else)
- **While loops**: Complete IR generation with proper break context
- **For loops**: Complete IR generation with loop variable management
- **Break statements**: Proper jump to enclosing loop exit labels
- **Break context threading**: Throughout semantic analysis
- **Assignment expressions**: Complete IR for simple, field, and subscript assignment
- **Array/Record access**: Field and subscript variable reading operations
- **Memory addressing**: Proper field offsets and array indexing
- **Array creation** (`ArrayExp`): Memory allocation and initialization
- **Record creation** (`RecordExp`): Memory allocation and field initialization  

### 🚧 Remaining for Core IR Generation
- **Let expressions** (`LetExp`): Variable and function declarations with scoping
- **Function calls**: Static link calculation implemented but needs testing

### 🔧 Advanced Features (Future)
- **String operations**: Concatenation and comparison
- **Runtime system**: Memory management, garbage collection
- **Optimization**: Register allocation, dead code elimination

## Next Steps for Implementation

1. **Let expressions**: Variable declarations with proper scoping
2. **Test function calls**: Verify static link passing works correctly

This architecture provides the foundation for generating correct IR code that properly handles Tiger's lexical scoping through static links and maintains the stack discipline required for function calls.
