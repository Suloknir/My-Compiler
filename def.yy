%{
#include <print>
#include <stack>
#include <string>
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2

extern "C" int yylex();
extern "C" int yyerror(const char *msg, ...);

enum ElementType
{
    T_ID,
    T_NUM,
    T_RESULT
};

struct Element
{
    ElementType type;
    std::string value;
};

std::stack<Element> valueStack;

void emitTriple(const char *op)
{
    Element rightArg = valueStack.top();
    valueStack.pop();
    Element leftArg = valueStack.top();
    valueStack.pop();
    
    static size_t result_counter = 1;
    Element result;
    result.type = T_RESULT;
    result.value = "result" + std::to_string(result_counter);

    std::println("bison: Left = {}, Right = {}, Result = {}", leftArg.value, rightArg.value, result.value);
    valueStack.push(result);
    result_counter++;
}

%}

%union 
{
    char *text;
    int	ival;
    float fval;
};
// %type <text> expression
%token <text> ID
%token <ival> NUM
%token ENDLINE
%left '+' '-'
%left '*' '/'
%right '='

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
    ;
expression
	:expression '+' term	{std::println("bison: wyrazenie z +"); emitTriple("+"); }
	|expression '-' term	{std::println("bison: wyrazenie z -"); emitTriple("-");}
	|term		{std::println("bison: wyrazenie pojedyncze");}
	;
term
	:term '*' factor	{std::println("bison: skladnik z *"); emitTriple("*");}
	|term '/' factor	{std::println("bison: skladnik z /"); emitTriple("/");}
	|factor		{std::println("bison: skladnik pojedynczy");}
	;
factor
	:ID			{
        std::println("bison: czynnik znakowy, {}", $1);
        Element el;
        el.type = T_ID;
        el.value = $1;
        valueStack.push(el);
        free($1);
    } 
	|NUM			{
        std::println("bison: czynnik liczbowy, {}", $1);
        Element el;
        el.type = T_NUM;
        el.value = std::to_string($1);
        valueStack.push(el);
    }
	|'(' expression ')'		{std::println("bison: wyrazenie w nawiasach");}
	;
assignment
    : ID '=' expression {
        std::println("bison: przypisanie");
        Element rightArg = valueStack.top();
        valueStack.pop();
        // std::println("bison: result = {}, {}", $1, rightArg.value);
        free($1);
    }
    ;

%%
int main(int argc, char *argv[])
{
	yyparse();
	return 0;
}