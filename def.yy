%{
#include "implementation.hpp"
%}

%union 
{
    char *text;
    int	ival;
    float fval;
    const char *branch;
};
// %type <text> expression
%token <text> ID
%token <ival> NUM
%token ENDLINE
%token PRINT
%token PRINTLN
%token READ
%token IF ELSE
%token EQ NE LE GE
%type <branch> condition
%precedence THEN
%precedence ELSE
// %left '+' '-'
%left '*' '/'
// %right '='


%start program
%%
program
    : statement_list
    |
    ;
statement_list
    : statement_list statement
    | statement 
    ;
statement
    : expression ENDLINE { valueStack.pop(); }
    | assignment ENDLINE
    | command ENDLINE
    | if_statement
    | block
    ;
block
    : '{' statement_list '}'
    | '{' '}'
    ;
if_statement
    : if_begin statement %prec THEN { emitIfEnd(); }
    | if_begin statement else_begin statement{ emitIfEnd(); }
    ;
if_begin 
    : IF '(' condition ')' { emitConditionalJump($3); }
    ;
else_begin
    : ELSE { emitElse(); }
    ;
condition
    : expression EQ expression      { $$ = "bne"; }
    | expression NE expression      { $$ = "beq"; }
    | expression '<' expression     { $$ = "bge"; }
    | expression '>' expression     { $$ = "ble"; }
    | expression LE expression      { $$ = "bgt"; }
    | expression GE expression      { $$ = "blt"; }
    | expression
    {
        valueStack.push(Operand{OperandKind::CONSTANT, DataType::INT, "0"});
        $$ = "beq";
    }
    ;
expression
	:expression '+' term	{ emitTriple("add"); }
	|expression '-' term	{ emitTriple("sub"); }
	|term		{std::println("Bison: wyrazenie pojedyncze");}
	;
term
	:term '*' factor	{ emitTriple("mul");}
	|term '/' factor	{ emitTriple("div");}
	|factor
	;
factor
	:ID			{
        Operand op{OperandKind::VARIABLE, getVariableType($1), $1};
        valueStack.push(op);
        free($1);
    } 
	|NUM			{
        Operand op{OperandKind::CONSTANT, DataType::INT, std::to_string($1)};
        valueStack.push(op);
    }
	|'(' expression ')'
	;
assignment
    : ID '=' expression {
        Operand value = valueStack.top();
        valueStack.pop();
        addSymbol($1, value.type);
        loadToRegister(value, "$t0");
        code.push_back("sw $t0, " + std::string($1));
        free($1);
    }
    ;
command
    : PRINT '(' expression ')' {
        Operand value = valueStack.top();
        valueStack.pop();
        emitPrint(value);
    }
    | PRINTLN '(' expression ')' {
        Operand value = valueStack.top();
        valueStack.pop();
        emitPrintln(value);
    }
    | READ '(' ID ')' {
        emitRead($3);
        free($3);
    }
    ;

%%
int main(int argc, char *argv[])
{
	yyparse();
    std::ofstream outFile("code.asm");
    outFile << ".data\n";
    for (auto &[name, symbol] : symbols)
    {
        //todo: check if float, then change word to sth else
        outFile << "\t" << name << ":\t.word 0\n";
    }

    outFile << ".text\n";
    outFile << "main:\n";
    for (auto &line : code)
    {
        if (line.back() == ':')
            outFile << line << "\n";
        else
            outFile << "\t" << line << "\n";
    }
    outFile << "\tli  $v0, 10\n\tsyscall\n";
    outFile.close();
    std::println("Saved to 'code.asm'");
	return 0;
}