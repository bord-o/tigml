%{
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
%token PLUS MINUS UMINUS TIMES DIVIDE EQ NEQ LT LE GT GE
%token AND OR ASSIGN
%token BREAK NIL
%token FUNCTION VAR TYPE 

%nonassoc SEMICOLON  // nonassociative for sequences of statements
%left OR
%left AND
%nonassoc EQ NEQ // nonassociative, doesn't allow a == b == c
%nonassoc LT LE GT GE // nonassociative, doesn't allow a < b < c
%left PLUS MINUS
%left TIMES DIVIDE
%right UMINUS  // right associative for unary minus: a = - - b

%nonassoc THEN
%nonassoc ELSE  // Nonassociative ELSE for the 'dangling else' problem

%nonassoc DO     // for the 'while' construct
%nonassoc TO     // for the 'for' construct
%nonassoc OF     // for the 'array of' construct

%start <unit> main

%%

(* -------------------------------------------------------------------------- *)

(* We wish to parse an expression followed with an end-of-line. *)

main:
  | exp EOF {(pp "main -> exp EOF")}

exp : 
	| LET decs IN optexp END {(pp "exp ->let in end")}
	| FOR ID ASSIGN exp TO exp DO exp %prec TO {(pp "exp -> for")}
  | IF exp THEN exp ELSE exp %prec ELSE {(pp "exp -> if then else")}
	| IF exp THEN exp %prec THEN {(pp "exp -> if then")}
	| WHILE exp DO exp %prec DO {(pp "exp -> while")}
	| lvalue_exp {(pp "exp -> lvalue_exp")}
	| lvalue ASSIGN exp {(pp "exp -> assignment")}
	| LPAREN optexp RPAREN {(pp "exp -> (optexp)")}
	| exp SEMICOLON exp {(pp "exp -> exp;exp")}
	| recordexp {(pp "exp -> recordexp")}

	| STRING {(pp "exp -> string")}
	| INT {(pp "exp -> int")}
	| ID {(pp "exp -> ID")}
	| BREAK {(pp "exp -> Break")}
	| UMINUS exp {(pp "exp -> uminus exp")}
	| exp EQ exp {(pp "exp -> beq")}
	| exp NEQ exp {(pp "exp -> bneq")}
	| exp TIMES exp {(pp "exp -> btimes")}
	| exp MINUS exp {(pp "exp -> bminus")}
	| exp DIVIDE exp {(pp "exp -> bdivide")}
	| exp PLUS exp {(pp "exp -> bplus")}
	| exp GT exp {(pp "exp -> gt")}
	| exp LT exp {(pp "exp -> lt")}
	| exp GE exp {(pp "exp -> ge")}
	| exp LE exp {(pp "exp -> le")}
	| exp AND exp {(pp "exp -> and")}
	| exp OR exp {(pp "exp -> or")}
		
	| ID LBRACK exp RBRACK OF exp %prec OF {(pp "exp -> id[ex] of exp ")}

	| NIL {(pp "exp -> exp")}

recordexp : ID LPAREN explist RPAREN {(pp "recordexp -> id(explist)")}
          | ID LBRACE recordargs RBRACE {(pp "recordexp -> id{recordargs}")}
          | ID NIL {(pp "recordexp -> id nil")}

optexp :
	| empty {(pp "optexp -> empty")}
	| exp {(pp "optexp -> exp")}
	
explist :
	| empty {(pp "explist -> empty")}
	| exp {(pp "explist -> single")}
	| exp COMMA explist {(pp "explist multiple")}
	
decs : 
	| dec {(pp "decs -> single")}
	| decs dec {(pp @@ "decs -> multiple")}

dec : 
	| tydec	{(pp "dec -> type")}
	| vardec	{(pp "dec -> var")}
	| fundec	{(pp "dec -> func")}

tydec : 
	| TYPE ID EQ ty	{(pp "tydec")}

ty : 
	| ID	{(pp "ty -> id")}
	| LBRACE tyfields RBRACE {(pp "ty -> {tyfields}")}
	| ARRAY OF ID	{(pp "ty -> array of id")}

tyfields : 
	| empty	{(pp "tyfields -> empty")}
	| ID COLON ID COMMA tyfields	{(pp "tyfields -> with comma")}
	| ID COLON ID 	{(pp "tyfields -> single")}

vardec :
	| VAR ID ASSIGN exp	{(pp "vardec -> no type")}
	| VAR ID COLON ID ASSIGN exp	{(pp "vardec -> w/type")}

fundec :
	| FUNCTION ID LPAREN tyfields RPAREN EQ exp	{(pp "funcdec -> notype")}
	| FUNCTION ID LPAREN tyfields RPAREN COLON ID EQ exp	{(pp "funcdec -> w/type")}

lvalue :
	| ID {(pp "lvalue -> id")}
	| lvalue_exp {(pp "lvalue -> lvalue_exp")}

lvalue_exp :
	| lvalue DOT ID {(pp "lvalue_exp -> lvalue.id")}
	| lvalue_exp LBRACK exp RBRACK {(pp "lvalue_exp -> lvalue[exp]")}
	| ID LBRACK exp RBRACK {(pp "lvalue_exp -> id[exp]")}
	
recordargs :
	| empty {(pp "recordargs -> empty")}
	| ID EQ exp {(pp "recordargs -> single")}
	| ID EQ exp COMMA recordargs {(pp "recordargs -> multiple ")}
	
empty : {(pp "empty")}
