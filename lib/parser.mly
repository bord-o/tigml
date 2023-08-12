%{
	open Absyn

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

%type <exp> exp
(*
%type <var> vardec
%type <ty> ty
%type <fundec> fundec
%type <dec list> decs
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


%start <exp> main

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
	| lvalue_exp {(pp "exp -> lvalue_exp"); VarExp $1}
	| lvalue ASSIGN exp {(pp "exp -> assignment"); AssignExp {var=$1; exp=$3; pos=0}}
	| LPAREN  RPAREN {(pp "exp -> ()"); SeqExp []}
	| LPAREN exp RPAREN {(pp "exp -> (optexp)"); $2}
	| exp SEMICOLON exp {(pp "exp -> exp;exp"); (
		match $3 with
		| SeqExp [] -> SeqExp (($1, 0) :: [ (SeqExp [], 0) ])
    | SeqExp exps -> SeqExp (($1, 0) :: exps)
		| _ -> SeqExp [($1,0);($3,0)]
)}

	| str=STRING {(pp "exp -> string"); StringExp (str, 0)}
	| i=INT {(pp "exp -> int"); IntExp (i)}
  | MINUS exp %prec UMINUS {(pp "exp -> uminus"); OpExp {left=(IntExp 0); oper=MinusOp; right=$2; pos=0}}
	| id=ID {(pp "exp -> ID"); VarExp (SimpleVar(id, 0))}
	| BREAK {(pp "exp -> Break"); BreakExp 0}
	| exp EQ exp {(pp "exp -> beq"); OpExp {left=$1; oper=EqOp; right=$3; pos=0}}
	| exp NEQ exp {(pp "exp -> bneq"); OpExp {left=$1; oper=NeqOp; right=$3; pos=0}}
	| exp TIMES exp {(pp "exp -> btimes"); OpExp {left=$1; oper=TimesOp; right=$3; pos=0}}
	| exp MINUS exp {(pp "exp -> bminus"); OpExp {left=$1; oper=MinusOp; right=$3; pos=0}}
	| exp DIVIDE exp {(pp "exp -> bdivide"); OpExp {left=$1; oper=DivideOp; right=$3; pos=0}}
	| exp PLUS exp {(pp "exp -> bplus"); OpExp {left=$1; oper=PlusOp; right=$3; pos=0}}
	| exp GT exp {(pp "exp -> gt"); OpExp {left=$1; oper=GtOp; right=$3; pos=0}}
	| exp LT exp {(pp "exp -> lt"); OpExp {left=$1; oper=LtOp; right=$3; pos=0}}
	| exp GE exp {(pp "exp -> ge"); OpExp {left=$1; oper=GeOp; right=$3; pos=0}}
	| exp LE exp {(pp "exp -> le"); OpExp {left=$1; oper=LeOp; right=$3; pos=0}}

	| exp AND exp {(pp "exp -> and"); IfExp {test=$1; then'=$3; else' = Some (IntExp 0); pos=0}}
	| exp OR exp {(pp "exp -> or"); IfExp {test=$1; then'=IntExp 1; else' = Some $3; pos=0}}
		
	| ID LBRACK exp RBRACK OF exp %prec OF {(pp "exp -> id[ex] of exp "); ArrayExp {typ=$1; size=$3; init=$6; pos=0}}
	| ID LBRACE recordargs RBRACE {(pp "exp ->id{recordargs}"); RecordExp {fields=$3; typ=$1; pos=0}}
	| ID LPAREN explist RPAREN {(pp "exp -> id(explist)"); CallExp {func=$1; args=$3; pos=0 }}

	| NIL {(pp "exp -> exp"); NilExp}

optexp :
	| empty {(pp "optexp -> empty"); $1}
	| exp {(pp "optexp -> exp"); $1}
	
explist :
	| empty {(pp "explist -> empty"); []}
	| exp {(pp "explist -> single"); $1 :: []}
	| exp COMMA explist {(pp "explist multiple"); $1 :: $3}
	
decs : 
	| dec {(pp "decs -> single"); $1 :: []}
	| decs dec {(pp @@ "decs -> multiple"); 
		(match ($2, $1) with
			(TypeDec [t], TypeDec ts :: ds) -> TypeDec (t :: ts) :: ds
			| (FunctionDec [f], FunctionDec fs :: ds) -> FunctionDec (f :: fs) :: ds
			| (d, ds) -> d :: ds
		)

}

dec : 
	| tydec	{(pp "dec -> type"); $1}
	| vardec	{(pp "dec -> var"); $1}
	| fundec	{(pp "dec -> func"); $1}

tydec : 
	| TYPE ID EQ ty	{(pp "tydec"); TypeDec [{name=$2; ty=$4; pos=0}]}

ty : 
	| ID	{(pp "ty -> id"); NameTy ($1, 0)}
	| LBRACE tyfields RBRACE {(pp "ty -> {tyfields}"); RecordTy $2}
	| ARRAY OF ID	{(pp "ty -> array of id"); ArrayTy ($3,0)}

tyfields : 
	| empty	{(pp "tyfields -> empty"); []}
	| ID COLON ID COMMA tyfields	{(pp "tyfields -> with comma");{name=$1; escape=ref false; typ=$3; pos=0} :: $5 }
	| ID COLON ID 	{(pp "tyfields -> single"); {name=$1; escape=ref false; typ=$3; pos=0} :: []}

vardec :
	| VAR ID ASSIGN exp	{(pp "vardec -> no type"); VarDec {name=$2; escape=ref true; typ=None; init=$4; pos=0}}
	| VAR ID COLON ID ASSIGN exp	{(pp "vardec -> w/type");  VarDec {name=$2; escape=ref true; typ=Some($4, 0); init=$6; pos=0}}

fundec :
	| FUNCTION ID LPAREN tyfields RPAREN EQ exp	{(pp "funcdec -> notype");FunctionDec [ {name=$2; params=$4; result=None; body=$7; pos=0}] }
	| FUNCTION ID LPAREN tyfields RPAREN COLON ID EQ exp	{(pp "funcdec -> w/type"); FunctionDec [ {name=$2; params=$4; result=Some($7, 0); body=$9; pos=0}]}

lvalue :
	| ID {(pp "lvalue -> id"); SimpleVar ($1,0)}
	| lvalue_exp {(pp "lvalue -> lvalue_exp"); $1}

lvalue_exp :
	| lvalue DOT ID {(pp "lvalue_exp -> lvalue.id"); FieldVar ($1, $3, 0)}
	| lvalue_exp LBRACK exp RBRACK {(pp "lvalue_exp -> lvalue[exp]"); SubscriptVar ($1, $3, 0)}
	| ID LBRACK exp RBRACK {(pp "lvalue_exp -> id[exp]"); SubscriptVar (SimpleVar ($1, 0),$3, 0 )}
	
recordargs :
	| empty {(pp "recordargs -> empty"); []}
	| ID EQ exp {(pp "recordargs -> single") ;($1, $3, 0) :: []}
	| ID EQ exp COMMA recordargs {(pp "recordargs -> multiple "); ($1, $3, 0) :: $5}
	
empty : {(pp "empty"); SeqExp []}
