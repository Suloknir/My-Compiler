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
\+			{fprintf(yyout, "flex: +\n");return '+';}
\*			{fprintf(yyout, "flex: *\n");return '*';}
\(			{fprintf(yyout, "flex: (\n");return '(';}
\)			{fprintf(yyout, "flex: )\n");return ')';}
\/			{fprintf(yyout, "flex: /\n");return '/';}
\-			{fprintf(yyout, "flex: -\n");return '-';}
\^			{fprintf(yyout, "flex: ^\n");return '^';}
\=			{fprintf(yyout, "flex: =\n");
			 return '=';}
";"       {return ENDLINE;}
[1-9][0-9]*		{
				fprintf(yyout, "flex: liczba\n");
				yylval.ival = atoi(yytext);
				return NUM;
			}	
[A-Za-z_][A-Za-z0-9_]*	{
				fprintf(yyout, "flex: nazwa\n");
				yylval.text = strdup(yytext);
				return ID;
			}
[1-9]+[.]{2}		{fprintf(yyout, "flex: dziwne\n");}
\ |\t|\r			{;}
\n			{
    yylineno++;
    // return '\n';
}
.			{yyerror("flex: Blad leksykalny\n");}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}

