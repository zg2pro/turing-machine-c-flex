%option yylineno 
%{
#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include <stdlib.h>
#include <linux/types.h>

//The TAPE of the machine
char *TAPE;
//position where the R/W head is currently working
int position = 0;
//size of the TAPE
int size;
//nb is a counter of instructions, usefull only for displaying
int nb = 1;

//typedef char tetat[3];
typedef char tsign1; //used to be called symbole
typedef char tsign2; //used to be called action

//structure to store instructions
typedef struct {
        tsign1 sign1;
        char iState [3];
        tsign2 sign2;
        char fState [3];
} tinst;

//a node is a list element
typedef struct tnode {
  tinst inst;
  struct tnode *next;
} tnode;

typedef tnode * tlist;

//to put nodes in the list (insertions are made at the head of the list)
void put(tinst inst, tlist *list) {
	tlist aux = NULL;
	aux = (tlist) malloc(sizeof(tnode));
	aux->inst = inst;
	aux->next = (*list);
	(*list) = aux;
}//put

//declaration of the list
tlist program;

//displaying function of the list : just to ensure the list has been stored
void displayList (tlist l){
	printf(" Liste : ");
	//list pointer
	int i=1;
	while (l){
		printf("  elem %d : %s",i++, l->inst.iState);
		//if (p!=l.tip) printf(" -> ");
		l = l->next;
	}//while
	printf("\n");
}//display

//function given in the statement to manage access in the tape
unsigned int ZN (int k){
	return (k<0) ? -(2*k + 1) : 2*k;
}//ZN


// to register the file instructions into the list
void addInstruction(char *text) {
	//reading from file .tur the instructions
	tinst inst;
	sscanf(text,"%[^,],%c,%c,%2s",&inst.iState,//current_state,
	&inst.sign1, &inst.sign2, &inst.fState);//current_sign, inst.sign_to_put, inst.next_state);

	//displaying instruction just been read
	printf("Instruction %d : %s, %c, %c, %s \n", nb++, inst.iState, inst.sign1, inst.sign2, inst.fState);
	//insertion in instructions list
	put(inst, &program);
}//addInstruction

//displaying the moving tape
void display(int begin, int end){
	int i;
	printf(" _ _ _ _ _ _ _ _ _ ");
	for (i=begin; i<end; i++)
		(i != position)? printf("\033[1;33m\033[40m%c\033[0m",TAPE[ZN(i)]) :
				printf("\033[1;33m\033[43m%c\033[0m",TAPE[ZN(i)]);
	//to keep the history
	printf("\n");
}//display

//look for differences between two strings, it returns 1 if the given strings are the same
int compareStrings (char a[3], char b[3]){
	int i;
	for(i=0; i<3; i++) if(a[i] != b[i]) return 0;
	return 1;
}//compareStrings

//look for the needed instruction in the list
tlist searchInstruction(char q[3], tsign1 sign, tlist aux) {
	while (aux != NULL) {
		if ((compareStrings(aux->inst.iState, q)) && (sign == aux->inst.sign1)) {
			return aux;
		} else {
			aux = aux->next;
		}//else
	}//while
	return aux;
}//searchInstruction

%}

/* lexical analysis */

LETTER  	[A-Z]|[a-z]
NUMERAL 	[0-9]
LEFTRIGHT	("<"|">")
SPACE 		(" ")
SIGN	 	({NUMERAL}|{LETTER}|{SPACE})
STATE		({LETTER}{NUMERAL})
MOVE		({LEFTRIGHT}|{SIGN})
INSTRUCTION	({STATE}","{SIGN}","{MOVE}","{STATE})

%%

{INSTRUCTION}	{addInstruction(yytext);}
{MOVE} {printf("MOVE %s ",yytext);}
{SIGN} {printf("SIGN %s ",yytext);}
{STATE} { printf("STATE %s ",yytext);}
.

%%

int main(int argc, char *argv[]) {
 
	int i; //usefull for loops
        program = NULL;

	if (argc<3) {
		printf("commande : ./turing [instrutions file .tur] [contents of the machine]\n");
		return 0;
	}

	/**
	First step : lexical analysis
	*/
	printf("Liste des instructions\n");
	yyin = fopen(argv[1], "r" );

        yylex();
        fclose(yyin);

	//displayList(instructions);
	/**
	Second step : To fill the machine with the wanted symbols
	*/
	char *firstTAPE;
	firstTAPE = strdup(argv[2]);
	firstTAPE = strcat(firstTAPE, " ");
	for (i=3; i<argc; i++){
		firstTAPE = (char*)realloc(firstTAPE, sizeof(char)*(3+strlen(firstTAPE)+strlen(argv[i])));
		firstTAPE = strcat(firstTAPE, argv[i]);
		firstTAPE = strcat(firstTAPE, " ");
	}
	TAPE = (char*)malloc(sizeof(char)*(2*strlen(firstTAPE)));
	size = (int)strlen(firstTAPE);
	for (i=0; i<size; i++){
		TAPE[ZN((-1)*i)] = ' ';
		TAPE[ZN(i)] = firstTAPE[i];
	}
	if (size<20) size=20;
	TAPE = (char*)realloc(TAPE, sizeof(char)*(size*2));
	for (i=((int)strlen(firstTAPE)); i<size; i++) {
		TAPE[ZN((-1)*i)] = ' ';
		TAPE[ZN(i)] = ' ';
	}
	free(firstTAPE);

	display(position-19, position+20);

	/**
	Final Step : Browse instructions and execute
	*/
	//declaration of an auxiliary list in order to browse program
        tlist list= program;
	while (list->next != NULL) list = list->next;
	//initial state is the first written in the .tur file, so the last in the list
	list = searchInstruction(list->inst.iState, (TAPE[ZN(position)]), program);

	while (list) {
		tsign2 a = (list->inst).sign2;

		printf ("%s  |%c| |%c| %s  ",(list->inst).iState, (list->inst).sign1, a, (list->inst).fState);
		switch (a) {
			case '<' : {
				position--;
				break;
			}
			case '>' : {
				position++;
				break;
			}
			default : TAPE[ZN(position)] = a;
			break;
		}//switch
		//if the position has been changed and is now out of the tape bounds, the tape has to be reallocated
		int tmp = (position>0)? position : position*(-1);
		if ((tmp + 20) > size){
			size = (tmp+20);
			TAPE = (char*)realloc(TAPE, sizeof(char)*(size*2));
			TAPE[ZN(1-size)] = ' ';
			TAPE[ZN(size-1)] = ' ';
		}
		sleep(1);
		display(position-19, position+20);
	
		list = searchInstruction((list->inst).fState, (TAPE[ZN(position)]), program);
	}//while

	return 1;	
}//main


