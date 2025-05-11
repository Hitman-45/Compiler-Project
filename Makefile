CFLAGS = -g -DDEBUG
CC = gcc

parser: y.tab.c lex.yy.c y.tab.h
	${CC} -w y.tab.c lex.yy.c -ll -o parser
lex.yy.c: ${fname}.l
	lex ${fname}.l
y.tab.c: ${fname}.y
	yacc -v -d -t ${fname}.y
clean:
	rm -f parser y.tab.c lex.yy.c lexer y.tab.h y.output *.out *.txt *.exe
