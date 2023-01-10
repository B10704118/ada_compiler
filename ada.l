%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
#define MAX_LINE_LENG 256
#define LIST {strcat(buffer,yytext);}
#define token(t) {LIST; return(t);}
#define tokenInteger(t,i) {LIST;}
#define tokenBoolean(t,i) {LIST; }
#define tokenString(t,s) {}

char buffer[MAX_LINE_LENG];
char strBuf[MAX_LINE_LENG];
int lineNum = 1;


int idNum = 0; //for symbol table
char symbolTable[100][256];

%}

letter          [a-zA-Z]
letters         [a-zA-Z]+
dig             [0-9]
digs            [0-9]+
string 			[ 0-9a-zA-Z:]*
id              {letter}([0-9a-zA-Z]*)
integer         {digs}
plain_real      {digs}"."{digs}
expreal         {digs}"."{digs}[Ee][+-]?{digs}
real            [+-]?{plain_real}|{expreal}
boolean         true|false

%x stringState
%x lineCommentState
%x blockCommentState

%%

 /* keywords */
begin       {token(BGN);}
boolean     {token(BOOLEAN);}
break       {token(BREAK);}
character   {token(CHARACTER);}
case        {token(CASE);}
continue    {token(CONTINUE);}
constant    {token(CONSTANT);}
declare     {token(DECLARE);}
do          {token(DO);}
else        {token(ELSE);}
end         {token(END);}
exit        {token(EXIT);}
for         {token(FOR);}
if          {token(IF);}
then        {token(THEN);}
in          {token(IN);}
integer     {token(INTEGER);}
loop        {token(LOOP);}
print       {token(_PRINT);}
println     {token(_PRINTLN);}
procedure   {token(PROCEDURE);}
program     {token(PROGRAM);}
return      {token(RETURN);}
string      {token(STRING);}
while       {token(WHILE);}
true		{token(TRUE); }
false		{token(FALSE);}

 /* operations */
and         {token(AND);}
or          {token(OR);}
not         {token(NOT);}
":="        {token(ASSIGN);}
","         {token(COMMA);}
":"         {token(COLON);}
"."         {token(PERIOD);}
";"         {token(SEMICOLON);}
"("         {token(LEFT_PARENTHESE);}
")"         {token(RIGHT_PARENTHESE);}
"["         {token(LEFT_BRACKET);}
"]"         {token(RIGHT_BRACKET);}
"+"         {token(PLUS);}
"-"         {token(SUB);}
"*"         {token(MULTIPLY);}
"/"         {token(DIV);}
"%"         {token(MOD);}
"<"         {token(LESS);}
"<="        {token(LEQ);}
">="        {token(GRQ);}
">"         {token(GREAT);}
"="         {token(EQUAL);}
"/="        {token(NEQ);}

 /* number */
{integer} {
    int tmp;
    sscanf(yytext,"%d",&tmp);
    tokenInteger("integer",tmp);
	sscanf(yytext,"%d",&yylval.intVal);
    token(INT_VAL);
}

 /* id */
{id} {
	strcat(buffer,yytext);
    tokenString("id",yytext);
	yylval.stringVal = strdup(yytext);
    token(ID);
}

\"{string}\" {
	LIST;
	yylval.stringVal = strdup(yytext);
	token(STR_VAL);
}


 /* new line */
\n|\r\n {
    LIST;
	lineNum++;
    buffer[0] = '\0';
}

 /* tab */
[ \t]*  {
    LIST;
}

 /* line comment */
-- {
	strcat(buffer,yytext);
	BEGIN lineCommentState;
}

<lineCommentState>\n {
    strcat(buffer,yytext);
	lineNum++;
    buffer[0] = '\0';
	BEGIN INITIAL;
}

<lineCommentState>. {
    strcat(buffer,yytext);
}

 /* block comment */
\{ {
    strcat(buffer,yytext);
    BEGIN blockCommentState;
}

<blockCommentState>\n {
    strcat(buffer,yytext);
	lineNum++;
    buffer[0] = '\0';
}

<blockCommentState>\} {
    strcat(buffer,yytext);
    BEGIN INITIAL;
}

<blockCommentState>. {
    strcat(buffer,yytext);
}

%%
