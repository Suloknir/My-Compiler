%{
#include <string.h>
#include <stdio.h>
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2

extern "C" int yylex();
extern "C" int yyerror(const char *msg, ...);

%}

%union 
{
    char *text;
    int	ival;
    float fval;
};
%type <text> expression
%token <text> ID
%token <ival> LC
%token ENDLINE
%left '+' '-'
%left '*' '/'
%right '='

%start program
%%
program
    : instructions
    // |program ENDLINE
    |
    ;
instructions
    : instructions instruction
    | instruction 
    ;
instruction
    : expression ENDLINE
    | assignment ENDLINE
    ;
expression
	:expression '+' addend	{printf("wyrazenie z + \n");}
	|expression '-' addend	{printf("wyrazenie z - \n");}
	|addend		{printf("wyrazenie pojedyncze \n");}
	;
addend
	:addend '*' factor	{printf("skladnik z * \n");}
	|addend '/' factor	{printf("skladnik z / \n");}
	|factor		{printf("skladnik pojedynczy \n");}
	;
factor
	:ID			{printf("czynnik znakowy, %s\n", $1);} 
	|LC			{printf("czynnik liczbowy, %d\n", $1);}
	|'(' expression ')'		{printf("wyrazenie w nawiasach\n");}
	;
assignment
    : ID '=' expression {printf("przypisanie\n");}
    ;

%%
int main(int argc, char *argv[])
{
	yyparse();
	return 0;
}