#include <stdio.h>
#include <iostream.h>
#include <vector>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <limits>

char *BANDE;

unsigned int ZN (int k){
	return (k<0) ? -(2*k + 1) : 2*k;
}

void seeCaseContent (int position){
	printf("\033[1;37m\033[40m%c\033[0m", BANDE[ZN(position)]);
}

int accessPositionInTab (int position){
	unsigned int realPosition = ZN(position);
	if(realPosition > strlen(BANDE)) realloc(BANDE, sizeof(char)*(realPosition+1));
	return realPosition;
}
/*
void Rules (char* line){
	switch (line){
	
	}
}

void executeRule () {

}
*/
int main(int argc, char * argv[]){

	/**
	First step : To fill the machine with the wanted symbols
	*/
	char *firstBANDE;
	firstBANDE = strdup(argv[1]);
	firstBANDE = strcat(firstBANDE, " ");
	for (int i=2; i<argc; i++){
		realloc(firstBANDE, sizeof(char)*(3+strlen(firstBANDE)+strlen(argv[i])));
		firstBANDE = strcat(firstBANDE, argv[i]);
		firstBANDE = strcat(firstBANDE, " ");
	}
	BANDE = (char*)malloc(sizeof(char)*(2*strlen(firstBANDE)));
	for (int i=0; i<((int)strlen(firstBANDE)); i++)
		BANDE[ZN(i)] = firstBANDE[i];
	int size = (int)strlen(firstBANDE);
	free(firstBANDE);
	cout << size << endl;

	/**
	Second step : 
	*/
	for (int i=0; i<size; i++)
		seeCaseContent (i);


	return 0;

}

