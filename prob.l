%option noyywrap
%{
#include<stdio.h>
#include<stdlib.h>
#include"y.tab.h"
char buffer[2048];
void append(const char*str){
    if(strlen(buffer)+strlen(str)<2048){
        strcat(buffer,str);
    }else{
        fprintf(stderr,"BUFFER OVERFLOW");
        exit(1);
    }
}
%}

bin [01]
ws [ \t\n]
digit [0-9]
letter [A-Za-z]
letter_ [A-Za-z_]
alphanumeric [A-Za-z0-9_]

%%
[ \t\n] ;                   {  }
"#include"                  {  return HEAD; }
"<stdio.h>"                 {  return STDIO; }
"<stdlib.h>"                {  return STDLIB; }
"<string.h>"                {  return STRING; }
"main"                      {  return MAIN; }
"if"                        {  return IF; }
"else"                      {  return ELSE; }
"while"                     {  return WHILE; }
"for"                       {  return FOR; }
"int"                       {  return INT; }
"float"                     {  return FLOAT; }
"char"                      {  return CHAR; }
"void"                      {  return VOID; }
"return 0"                  {  return RETURN; }
\/\/.*                      { /* Ignore comments */ }
"/*"([^*]|\*+[^*/])*\*+"/"  { /* Ignore comments */ }
{digit}+(\.{digit}+)?       { strcpy(yylval.lexeme,yytext);return NUMBER; }
{letter_}{alphanumeric}*    { strcpy(yylval.lexeme,yytext);return ID; }
"++"                        {  return INCREMENT; }
"--"                        {  return DECREMENT; }
"+"                         {  return ADD; }
"-"                         {  return SUB; }
"*"                         {  return MUL; }
"/"                         {  return DIV; }
"%"                         {  return MOD; }
">"                         {  return GT; }
"<"                         {  return LT; }
">="                        {  return GTE; }
"<="                        {  return LTE; }
"=="                        {  return EQ; }
"!="                        {  return NE; }
"&&"                        {  return AND; }
"||"                        {  return OR; }
"!"                         {  return NOT; }
"("                         {  return LP; }
")"                         {  return RP; }
"{"                         {  return LC; }
"}"                         {  return RC; }
"="                         {  return ASSIGN; }
","                         {  return COMMA; }
":"                         {  return COLON; }
";"                         {  return SEMICOLON; }
.                           {  return yytext[0]; }
<<EOF>>                     { return 0; }
%%`
