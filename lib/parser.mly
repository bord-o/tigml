%{
	open Absyn
	module A = Absyn

	let debug = false
	let pp = if debug then print_endline else (fun _->())
%}

%token EOF 
%token <string> ID
%token <int> INT 
%token <string> STRING
%token LET IN END ARRAY IF THEN ELSE WHILE FOR TO DO OF 
%token COMMA COLON SEMICOLON LPAREN RPAREN LBRACK RBRACK 
%token LBRACE RBRACE DOT 
%token PLUS MINUS TIMES DIVIDE EQ NEQ LT LE GT GE
%token AND OR ASSIGN
%token BREAK NIL
%token FUNCTION VAR TYPE 

%type <A.exp> exp
(*
%type <A.var> vardec
%type <A.ty> ty
%type <A.fundec> fundec
%type <A.dec list> decs
*)


%right SEMICOLON
%left THEN
%left DO OF ELSE
%left ASSIGN
%left AND OR
%nonassoc EQ NEQ GT GE LT LE
%left PLUS MINUS
%left TIMES DIVIDE
%nonassoc TO
%left UMINUS


%start <A.exp> main

%%

(* -------------------------------------------------------------------------- *)

(* We wish to parse an expression followed with an end-of-line. *)

main:
  | exp EOF {(pp "main -> exp EOF"); $1}

exp : 
	| LET decs IN optexp END {(pp "exp ->let in end"); LetExp {decs=$2; body=$4; pos=0}}
	| FOR ID ASSIGN exp TO exp DO exp %prec TO {(pp "exp -> for"); ForExp {var=$2; escape=ref false; lo=$4; hi=$6; body=$8; pos=0}}
  | IF exp THEN exp ELSE exp %prec ELSE {(pp "exp -> if then else"); IfExp {test=$2; then'=$4; else'=Some($6); pos=0}}
	| IF exp THEN exp %prec THEN {(pp "exp -> if then"); IfExp {test=$2; then'=$4; else'=None; pos=0}}
	| WHILE exp DO exp %prec DO {(pp "exp -> while"); WhileExp {test=$2; body=$4; pos=0} }
	| lvalue_exp {(pp "exp -> lvalue_exp"); A.VarExp $1}
	| lvalue ASSIGN exp {(pp "exp -> assignment"); AssignExp {var=$1; exp=$3; pos=0}}
	| LPAREN  RPAREN {(pp "exp -> ()"); A.SeqExp []}
	| LPAREN exp RPAREN {(pp "exp -> (optexp)"); $2}
	| exp SEMICOLON exp {(pp "exp -> exp;exp"); (
		match $3 with
		| A.SeqExp [] -> A.SeqExp (($1, 0) :: [ (A.SeqExp [], 0) ])
    | A.SeqExp exps -> A.SeqExp (($1, 0) :: exps)
		| _ -> A.SeqExp [($1,0);($3,0)]
)}

	| str=STRING {(pp "exp -> string"); A.StringExp (str, 0)}
	| i=INT {(pp "exp -> int"); A.IntExp (i)}
  | MINUS exp %prec UMINUS {(pp "exp -> uminus"); A.OpExp {left=(A.IntExp 0); oper=A.MinusOp; right=$2; pos=0}}
	| id=ID {(pp "exp -> ID"); A.VarExp (SimpleVar(id, 0))}
	| BREAK {(pp "exp -> Break"); A.BreakExp 0}
	| exp EQ exp {(pp "exp -> beq"); A.OpExp {left=$1; oper=A.EqOp; right=$3; pos=0}}
	| exp NEQ exp {(pp "exp -> bneq"); A.OpExp {left=$1; oper=A.NeqOp; right=$3; pos=0}}
	| exp TIMES exp {(pp "exp -> btimes"); A.OpExp {left=$1; oper=A.TimesOp; right=$3; pos=0}}
	| exp MINUS exp {(pp "exp -> bminus"); A.OpExp {left=$1; oper=A.MinusOp; right=$3; pos=0}}
	| exp DIVIDE exp {(pp "exp -> bdivide"); A.OpExp {left=$1; oper=A.DivideOp; right=$3; pos=0}}
	| exp PLUS exp {(pp "exp -> bplus"); A.OpExp {left=$1; oper=A.PlusOp; right=$3; pos=0}}
	| exp GT exp {(pp "exp -> gt"); A.OpExp {left=$1; oper=A.GtOp; right=$3; pos=0}}
	| exp LT exp {(pp "exp -> lt"); A.OpExp {left=$1; oper=A.LtOp; right=$3; pos=0}}
	| exp GE exp {(pp "exp -> ge"); A.OpExp {left=$1; oper=A.GeOp; right=$3; pos=0}}
	| exp LE exp {(pp "exp -> le"); A.OpExp {left=$1; oper=A.LeOp; right=$3; pos=0}}

	| exp AND exp {(pp "exp -> and"); A.IfExp {test=$1; then'=$3; else' = Some (A.IntExp 0); pos=0}}
	| exp OR exp {(pp "exp -> or"); A.IfExp {test=$1; then'=A.IntExp 1; else' = Some $3; pos=0}}
		
	| ID LBRACK exp RBRACK OF exp %prec OF {(pp "exp -> id[ex] of exp "); A.ArrayExp {typ=$1; size=$3; init=$6; pos=0}}
	| ID LBRACE recordargs RBRACE {(pp "exp ->id{recordargs}"); A.RecordExp {fields=$3; typ=$1; pos=0}}
	| ID LPAREN explist RPAREN {(pp "exp -> id(explist)"); A.CallExp {func=$1; args=$3; pos=0 }}

	| NIL {(pp "exp -> exp"); A.NilExp}

optexp :
	| empty {(pp "optexp -> empty"); $1}
	| exp {(pp "optexp -> exp"); $1}
	
explist :
	| empty {(pp "explist -> empty"); []}
	| exp {(pp "explist -> single"); $1 :: []}
	| exp COMMA explist {(pp "explist multiple"); $1 :: $3}
	
decs : 
	| dec {(pp "decs -> single"); $1 :: []}
	| decs dec {(pp @@ "decs -> multiple"); $2 :: $1}

dec : 
	| tydec	{(pp "dec -> type"); $1}
	| vardec	{(pp "dec -> var"); $1}
	| fundec	{(pp "dec -> func"); $1}

tydec : 
	| TYPE ID EQ ty	{(pp "tydec")}

ty : 
	| ID	{(pp "ty -> id"); NameTy ($1, 0)}
	| LBRACE tyfields RBRACE {(pp "ty -> {tyfields}"); RecordTy $2}
	| ARRAY OF ID	{(pp "ty -> array of id"); ArrayTy ($3,0)}

tyfields : 
	| empty	{(pp "tyfields -> empty"); []}
	| ID COLON ID COMMA tyfields	{(pp "tyfields -> with comma");{name=$1; escape=ref false; typ=$3; pos=0} :: $5 }
	| ID COLON ID 	{(pp "tyfields -> single"); {name=$1; escape=ref false; typ=$3; pos=0} :: []}

vardec :
	| VAR ID ASSIGN exp	{(pp "vardec -> no type")}
	| VAR ID COLON ID ASSIGN exp	{(pp "vardec -> w/type")}

fundec :
	| FUNCTION ID LPAREN tyfields RPAREN EQ exp	{(pp "funcdec -> notype"); }
	| FUNCTION ID LPAREN tyfields RPAREN COLON ID EQ exp	{(pp "funcdec -> w/type")}

lvalue :
	| ID {(pp "lvalue -> id"); A.SimpleVar ($1,0)}
	| lvalue_exp {(pp "lvalue -> lvalue_exp"); $1}

lvalue_exp :
	| lvalue DOT ID {(pp "lvalue_exp -> lvalue.id"); A.FieldVar ($1, $3, 0)}
	| lvalue_exp LBRACK exp RBRACK {(pp "lvalue_exp -> lvalue[exp]"); A.SubscriptVar ($1, $3, 0)}
	| ID LBRACK exp RBRACK {(pp "lvalue_exp -> id[exp]"); A.SubscriptVar (A.SimpleVar ($1, 0),$3, 0 )}
	
recordargs :
	| empty {(pp "recordargs -> empty"); []}
	| ID EQ exp {(pp "recordargs -> single") ;($1, $3, 0) :: []}
	| ID EQ exp COMMA recordargs {(pp "recordargs -> multiple "); ($1, $3, 0) :: $5}
	
empty : {(pp "empty"); A.SeqExp []}
