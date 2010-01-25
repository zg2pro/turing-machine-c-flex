LIB=-lfl
CC=gcc

turing: turing.c
	$(CC) -o turing turing.c $(LIB) -g

turing.c: turing.lex
	flex -o turing.c turing.lex
