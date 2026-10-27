CXX=g++
CC=gcc
LEX=flex
YACC=bison
LD=gcc

all:	leks

leks:	def.tab.o lex.yy.o
	$(CXX) -std=c++11 lex.yy.o def.tab.o -o leks -ll

lex.yy.o:	lex.yy.c
	$(CC) -c lex.yy.c

lex.yy.c: flex.l
	$(LEX) flex.l

def.tab.o:	def.tab.cc
	$(CXX) -std=c++11 -c def.tab.cc

def.tab.cc:	def.yy
	$(YACC) -d def.yy

clean:
	rm *.o leks def.tab.cc lex.yy.c def.tab.hh
