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
\+			{fprintf(yyout, "Flex: +\n");return '+';}
\*			{fprintf(yyout, "Flex: *\n");return '*';}
\(			{fprintf(yyout, "Flex: (\n");return '(';}
\)			{fprintf(yyout, "Flex: )\n");return ')';}
\/			{fprintf(yyout, "Flex: /\n");return '/';}
\-			{fprintf(yyout, "Flex: -\n");return '-';}
\^			{fprintf(yyout, "Flex: ^\n");return '^';}
\=			{fprintf(yyout, "Flex: =\n");
			 return '=';}
";"       {return ENDLINE;}
0|[1-9][0-9]*		{
				fprintf(yyout, "Flex: liczba\n");
				yylval.ival = atoi(yytext);
				return NUM;
			}	
[A-Za-z_][A-Za-z0-9_]*	{
				fprintf(yyout, "Flex: nazwa\n");
				yylval.text = strdup(yytext);
				return ID;
			}
[1-9]+[.]{2}		{fprintf(yyout, "Flex: dziwne\n");}
\ |\t|\r			{;}
\n			{
    yylineno++;
    // return '\n';
}
.			{yyerror("Flex: Blad leksykalny\n");}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}

