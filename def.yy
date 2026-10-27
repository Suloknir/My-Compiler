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
%type <text> wyr
%token <text> ID
%token <ival> LC
%token ENDLINE
%left '+' '-'
%left '*' '/'
%right '='

%start program
%%
program
    : instrukcje
    // |program ENDLINE
    |
    ;
instrukcje
    : instrukcje instrukcja
    | instrukcja 
    ;
instrukcja
    : wyr ENDLINE
    | przypisanie ENDLINE
    ;
wyr
	:wyr '+' skladnik	{printf("wyrazenie z + \n");}
	|wyr '-' skladnik	{printf("wyrazenie z - \n");}
	|skladnik		{printf("wyrazenie pojedyncze \n");}
	;
skladnik
	:skladnik '*' czynnik	{printf("skladnik z * \n");}
	|skladnik '/' czynnik	{printf("skladnik z / \n");}
	|czynnik		{printf("skladnik pojedynczy \n");}
	;
czynnik
	:ID			{printf("czynnik znakowy, %s\n", $1);} 
	|LC			{printf("czynnik liczbowy, %d\n", $1);}
	|'(' wyr ')'		{printf("wyrazenie w nawiasach\n");}
	;
przypisanie
    : ID '=' wyr {printf("przypisanie\n");}
    ;

%%
int main(int argc, char *argv[])
{
	yyparse();
	return 0;
}