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
%type <dec> dec
%type <dec> tydec
%type <dec list> decs
%type <ty> ty
%type <field list> tyfields
%type <dec> vardec
%type <dec> fundec
%type <exp> optexp
%type <exp list> explist
%type <(symbol * exp * pos) list> recordargs
%type <var> lvalue
%type <var> lvalue_exp

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
	| LET decs IN optexp END {(pp "exp ->let in end"); LetExp {decs=$2; body=$4; pos=$startpos}}
	| FOR ID ASSIGN exp TO exp DO exp %prec TO {(pp "exp -> for"); ForExp {var=$2; escape=ref false; lo=$4; hi=$6; body=$8; pos=$startpos}}
  | IF exp THEN exp ELSE exp %prec ELSE {(pp "exp -> if then else"); IfExp {test=$2; then'=$4; else'=Some($6); pos=$startpos}}
	| IF exp THEN exp %prec THEN {(pp "exp -> if then"); IfExp {test=$2; then'=$4; else'=None; pos=$startpos}}
	| WHILE exp DO exp %prec DO {(pp "exp -> while"); WhileExp {test=$2; body=$4; pos=$startpos} }
	| lvalue_exp {(pp "exp -> lvalue_exp"); VarExp $1}
	| lvalue ASSIGN exp {(pp "exp -> assignment"); AssignExp {var=$1; exp=$3; pos=$startpos}}
	| LPAREN  RPAREN {(pp "exp -> ()"); SeqExp []}
	| LPAREN exp RPAREN {(pp "exp -> (optexp)"); $2}
	| exp SEMICOLON exp {(pp "exp -> exp;exp"); (
		match $3 with
		| SeqExp [] -> SeqExp (($1, $startpos) :: [ (SeqExp [], $startpos) ])
	   	| SeqExp exps -> SeqExp (($1, $startpos) :: exps)
		| _ -> SeqExp [($1,$startpos);($3,$startpos)]
)}

	| str=STRING {(pp "exp -> string"); StringExp (str, $startpos)}
	| i=INT {(pp "exp -> int"); IntExp (i)}
  	| MINUS exp %prec UMINUS {(pp "exp -> uminus"); OpExp {left=(IntExp 0); oper=MinusOp; right=$2; pos=$startpos}}
	| id=ID {(pp "exp -> ID"); VarExp (SimpleVar(id, $startpos))}
	| BREAK {(pp "exp -> Break"); BreakExp $startpos}
	| exp EQ exp {(pp "exp -> beq"); OpExp {left=$1; oper=EqOp; right=$3; pos=$startpos}}
	| exp NEQ exp {(pp "exp -> bneq"); OpExp {left=$1; oper=NeqOp; right=$3; pos=$startpos}}
	| exp TIMES exp {(pp "exp -> btimes"); OpExp {left=$1; oper=TimesOp; right=$3; pos=$startpos}}
	| exp MINUS exp {(pp "exp -> bminus"); OpExp {left=$1; oper=MinusOp; right=$3; pos=$startpos}}
	| exp DIVIDE exp {(pp "exp -> bdivide"); OpExp {left=$1; oper=DivideOp; right=$3; pos=$startpos}}
	| exp PLUS exp {(pp "exp -> bplus"); OpExp {left=$1; oper=PlusOp; right=$3; pos=$startpos}}
	| exp GT exp {(pp "exp -> gt"); OpExp {left=$1; oper=GtOp; right=$3; pos=$startpos}}
	| exp LT exp {(pp "exp -> lt"); OpExp {left=$1; oper=LtOp; right=$3; pos=$startpos}}
	| exp GE exp {(pp "exp -> ge"); OpExp {left=$1; oper=GeOp; right=$3; pos=$startpos}}
	| exp LE exp {(pp "exp -> le"); OpExp {left=$1; oper=LeOp; right=$3; pos=$startpos}}

	| exp AND exp {(pp "exp -> and"); IfExp {test=$1; then'=$3; else' = Some (IntExp 0); pos=$startpos}}
	| exp OR exp {(pp "exp -> or"); IfExp {test=$1; then'=IntExp 1; else' = Some $3; pos=$startpos}}
		
	| ID LBRACK exp RBRACK OF exp %prec OF {(pp "exp -> id[ex] of exp "); ArrayExp {typ=$1; size=$3; init=$6; pos=$startpos}}
	| ID LBRACE recordargs RBRACE {(pp "exp ->id{recordargs}"); RecordExp {fields=$3; typ=$1; pos=$startpos}}
	| ID LPAREN explist RPAREN {(pp "exp -> id(explist)"); CallExp {func=$1; args=$3; pos=$startpos }}

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
	| TYPE ID EQ ty	{(pp "tydec"); TypeDec [{name=$2; ty=$4; pos=$startpos}]}

ty : 
	| ID	{(pp "ty -> id"); NameTy ($1, $startpos)}
	| LBRACE tyfields RBRACE {(pp "ty -> {tyfields}"); RecordTy $2}
	| ARRAY OF ID	{(pp "ty -> array of id"); ArrayTy ($3,$startpos)}

tyfields : 
	| empty	{(pp "tyfields -> empty"); []}
	| ID COLON ID COMMA tyfields	{(pp "tyfields -> with comma");{name=$1; escape=ref false; typ=$3; pos=$startpos} :: $5 }
	| ID COLON ID 	{(pp "tyfields -> single"); {name=$1; escape=ref false; typ=$3; pos=$startpos} :: []}

vardec :
	| VAR ID ASSIGN exp	{(pp "vardec -> no type"); VarDec {name=$2; escape=ref true; typ=None; init=$4; pos=$startpos}}
	| VAR ID COLON ID ASSIGN exp	{(pp "vardec -> w/type");  VarDec {name=$2; escape=ref true; typ=Some($4, $startpos); init=$6; pos=$startpos}}

fundec :
	| FUNCTION ID LPAREN tyfields RPAREN EQ exp	{(pp "funcdec -> notype");FunctionDec [ {name=$2; params=$4; result=None; body=$7; pos=$startpos}] }
	| FUNCTION ID LPAREN tyfields RPAREN COLON ID EQ exp	{(pp "funcdec -> w/type"); FunctionDec [ {name=$2; params=$4; result=Some($7, $startpos); body=$9; pos=$startpos}]}

lvalue :
	| ID {(pp "lvalue -> id"); SimpleVar ($1,$startpos)}
	| lvalue_exp {(pp "lvalue -> lvalue_exp"); $1}

lvalue_exp :
	| lvalue DOT ID {(pp "lvalue_exp -> lvalue.id"); FieldVar ($1, $3, $startpos)}
	| lvalue_exp LBRACK exp RBRACK {(pp "lvalue_exp -> lvalue[exp]"); SubscriptVar ($1, $3, $startpos)}
	| ID LBRACK exp RBRACK {(pp "lvalue_exp -> id[exp]"); SubscriptVar (SimpleVar ($1, $startpos),$3, $startpos )}
	
recordargs :
	| empty {(pp "recordargs -> empty"); []}
	| ID EQ exp {(pp "recordargs -> single") ;($1, $3, $startpos) :: []}
	| ID EQ exp COMMA recordargs {(pp "recordargs -> multiple "); ($1, $3, $startpos) :: $5}
	
empty : {(pp "empty"); SeqExp []}
