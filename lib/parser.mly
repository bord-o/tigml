%token EOF 
%token <string> ID
%token <int> INT 
%token <string> STRING
%token COMMA COLON SEMICOLON LPAREN RPAREN LBRACK RBRACK 
%token LBRACE RBRACE DOT 
%token PLUS MINUS UMINUS TIMES DIVIDE EQ NEQ LT LE GT GE
%token AND OR ASSIGN
%token ARRAY IF THEN ELSE WHILE FOR TO DO LET IN END OF 
%token BREAK NIL
%token FUNCTION VAR TYPE 

%left EQ NEQ
%left LT GT LE GE
%left PLUS MINUS
%left TIMES DIV
%right UMINUS


%start <unit> main

%%

(* -------------------------------------------------------------------------- *)

(* We wish to parse an expression followed with an end-of-line. *)

main:
  | exp EOF {()}

exp : 
	STRING {()}
	| INT {()}
	| ID {()}
	| BREAK {()}
	| UMINUS exp {()}
	| exp EQ exp {()}
	| exp NEQ exp {()}
	| exp TIMES exp {()}
	| exp MINUS exp {()}
	| exp DIVIDE exp {()}
	| exp PLUS exp {()}
	| exp GT exp {()}
	| exp LT exp {()}
	| exp GE exp {()}
	| exp LE exp {()}
	| exp AND exp {()}
	| exp OR exp {()}
	
	

	| ID LBRACK exp RBRACK OF exp {()}
	| ID LBRACE recordargs RBRACE {()}
	| ID LPAREN explist RPAREN {()}
	
	| FOR ID ASSIGN exp TO exp DO exp {()}
	| IF exp THEN exp ELSE exp {()}
	| IF exp THEN exp {()}
	| WHILE exp DO exp {()}
	| lvalue_exp {()}
	| lvalue ASSIGN exp {()}
	| LET decs IN optexp END {()}
	| LPAREN optexp RPAREN {()}
	| exp SEMICOLON exp {()}

	| NIL {()}

optexp :
	empty {()}
	| exp {()}
	
explist :
	empty {()}
	| exp {()}
	| exp COMMA explist {()}
	
decs : 
	dec {()}
	| decs dec {()}

dec : 
	tydec	{()}
	| vardec	{()}
	| fundec	{()}

tydec : TYPE ID EQ ty	{()}

ty : 
	ID	{()}
	| LBRACE tyfields RBRACE {()}
	| ARRAY OF ID	{()}

tyfields : 
	empty	{()}
	| ID COLON ID COMMA tyfields	{()}
	| ID COLON ID 	{()}

vardec :
	VAR ID ASSIGN exp	{()}
	| VAR ID COLON ID ASSIGN exp	{()}

fundec :
	FUNCTION ID LPAREN tyfields RPAREN EQ exp	{()}
	| FUNCTION ID LPAREN tyfields RPAREN COLON ID EQ exp	{()}

lvalue :
	ID {()}
	| lvalue_exp {()}

lvalue_exp :
	lvalue DOT ID {()}
	| lvalue_exp LBRACK exp RBRACK {()}
	| ID LBRACK exp RBRACK {()}
	
recordargs :
	empty {()}
	| ID EQ exp {()}
	| ID EQ exp COMMA recordargs {()}
	
empty : {()}
