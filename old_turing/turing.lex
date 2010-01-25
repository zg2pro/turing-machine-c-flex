%option yylineno 
%{
#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include <stdlib.h>
#include <linux/types.h>


char *TAPE;
int position = 0;
int size;
int nb = 1;

typedef struct {
	char current_state[3]; char next_state[3];
 	char current_sign, sign_to_put;
}Instruction;
typedef struct Elem {Instruction inst; struct Elem *rite;}elem;
typedef struct {elem *head, *tip;}list;


list instructions;

//insertion at the end of the list
void insertElem (elem *nu) {
	if (!instructions.head) {
		instructions.head = nu;
	} else {
		instructions.tip->rite = nu;
	}
	instructions.tip = nu;
	//instructions.tip->rite = NULL;
}

void displayList (list l){
	printf(" Liste : ");
	elem *p = l.head;
	while (p){
		printf("  zob  ");
		printf("%s", p->inst.current_state);
		if (p!=l.tip) printf(" -> ");
		p = p->rite;
	}
	printf("\n");
}


unsigned int ZN (int k){
	return (k<0) ? -(2*k + 1) : 2*k;
}


// to register the file instructions into the list
void addInstruction(char *text) {
	elem *nu;
	nu =  malloc(sizeof(*nu));
	sscanf(text,"%[^,],%c,%c,%2s",&nu->inst.current_state,
	&nu->inst.current_sign,&nu->inst.sign_to_put,
	&nu->inst.next_state);

	printf("Instruction %d : %s, %c, %c, %s \n", nb++,  nu->inst.current_state,nu->inst.current_sign,
	nu->inst.sign_to_put,nu->inst.next_state);
	insertElem(nu);
}

//displaying the moving band :D
void display(int begin, int end){
	int i;
	printf("\t\t\t");
	for (i=begin; i<end; i++)
		(i != position)? printf("\033[1;33m\033[40m%c\033[0m",TAPE[ZN(i)]) :
				printf("\033[1;33m\033[43m%c\033[0m",TAPE[ZN(i)]);
	printf("\n");
}

int compareStrings (char current_state[3], char next_state[3]){
	int i;
	for(i=0; i<3; i++) if(current_state[i] != next_state[i]) return 0;
	return 1;
}

void performInstructions(elem *p) {
	//printf("performin\n");
	//elem *p = instructions.head;
	if(p->inst.current_sign == TAPE[ZN(position)]) {
	//printf("state recognized\n");
		switch (p->inst.sign_to_put) {
			case '<' : position--;
			break;
			case '>' : position++;
			break;
			default : TAPE[ZN(position)] = p->inst.sign_to_put;
			break;
		}//switch
		int tmp = (position>0)? position : position*(-1);
		if ((tmp + 20) > size){
			size = (tmp+20);
			TAPE = (char*)realloc(TAPE, sizeof(char)*(size*2));
			TAPE[ZN(1-size)] = ' ';
			TAPE[ZN(size-1)] = ' ';
		}
		display(position-19, position+20);
	}
	fflush(stdout);
	elem *psearch = instructions.head;
	while(psearch) {
		if((compareStrings(p->inst.next_state, psearch->inst.current_state)) && (TAPE[ZN(position)] == psearch->inst.current_sign)) {
			sleep(1);
			p = psearch;
			performInstructions(p);
		} else {
      			psearch = psearch->rite;
    		}
	}
}

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
. //pr mettre a la ligne la premiere ligne

%%

int main(int argc, char *argv[]) {
 
	int i; 
	instructions.head=NULL;
	instructions.tip=NULL;

	if (argc<3) {
		printf("commande : ./turing [instrutions file .tur] [contents of the machine]\n");
		return 0;
	}
	printf("Liste des instructions\n");
	yyin = fopen(argv[1], "r" );

        yylex();
        fclose(yyin);

	//displayList(instructions);
	/**
	First step : To fill the machine with the wanted symbols
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
	size=20;
	TAPE = (char*)realloc(TAPE, sizeof(char)*(size*2));
	for (i=((int)strlen(firstTAPE)); i<size; i++) {
		TAPE[ZN((-1)*i)] = ' ';
		TAPE[ZN(i)] = ' ';
	}
	free(firstTAPE);
	display(position-19, position+20);
 	performInstructions(instructions.head);

	return 1;	
}

