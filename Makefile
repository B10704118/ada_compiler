all: lex.yy.o y.tab.o
	g++ -o parser -std=c11 lex.yy.o y.tab.o -ll

scanner: lex.yy.o y.tab.o
	g++ -o scanner lex.yy.o -ll

lex.yy.o: ada.l y.tab.h
	lex ada.l
	g++ -c -g lex.yy.c

y.tab.o: y.tab.h y.tab.c
	g++ -c  y.tab.c -std=c++11

y.tab.h y.tab.c: ada.y
	yacc -d -v ada.y

clean:
	rm -f *.o *.jasm *.class lex.yy.c y.tab.h y.tab.c y.output parser