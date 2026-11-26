%{
#include <stdlib.h>
#include <string.h>
#include "def.tab.hh"
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
extern int yylineno;
int yyerror(const char *, ...);
%}
%%
\+			{fprintf(yyout, "Flex %d: +\n", yylineno);return '+';}
\*			{fprintf(yyout, "Flex %d: *\n", yylineno);return '*';}
\(			{fprintf(yyout, "Flex %d: (\n", yylineno);return '(';}
\)			{fprintf(yyout, "Flex %d: )\n", yylineno);return ')';}
\/			{fprintf(yyout, "Flex %d: /\n", yylineno);return '/';}
\-			{fprintf(yyout, "Flex %d: -\n", yylineno);return '-';}
\^			{fprintf(yyout, "Flex %d: ^\n", yylineno);return '^';}
\=			{fprintf(yyout, "Flex %d: =\n", yylineno);
			 return '=';}
";"       {return ENDLINE;}
0|[1-9][0-9]*		{
				fprintf(yyout, "Flex %d: integer\n", yylineno);
				yylval.ival = atoi(yytext);
				return NUM;
			}
(0|[1-9][0-9]*)\.[0-9]+ {
                fprintf(yyout, "Flex %d: real number\n", yylineno);
                // yylval.fval = atof(yytext);
                yylval.text = strdup(yytext);
                return REAL_LITERAL;
            }            
"print" {
				fprintf(yyout, "Flex %d: print\n", yylineno);
                return PRINT;
            }
"println" {
				fprintf(yyout, "Flex %d: println\n", yylineno);
                return PRINTLN;
            }
"read" {
				fprintf(yyout, "Flex %d: read\n", yylineno);
                return READ;
            }
"if"        {return IF;}
"else"      {return ELSE;}
"=="        {return EQ;}
"!="        {return NE;}
"<="        {return LE;}
">="        {return GE;}
"<"         {return '<';}
">"         {return '>';}
"{"         {return '{';}
"}"         {return '}';}
[A-Za-z_][A-Za-z0-9_]*	{
				fprintf(yyout, "Flex %d: nazwa\n", yylineno);
				yylval.text = strdup(yytext);
				return ID;
			}
\"(\\.|[^"\\\n])*\" {
        fprintf(yyout, "Flex %d: string literal\n", yylineno);
        yylval.text = strdup(yytext);
        return STRING_LITERAL;
}
[1-9]+[.]{2}		{fprintf(yyout, "Flex %d: dziwne\n", yylineno);}
\ |\t|\r			{;}
\n			{
    yylineno++;
    // return '\n';
}
.			{yyerror("Flex %d: Blad leksykalny\n", yylineno);}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}

