// game_of_life.c
//
// Nvidia CUDA implementation of simultaneous game of life.
//
// Created by Filip Jany & Patryk Stopyra
// Wroclaw, 22.05.2015.

#include "gol_engine.h"

#define FORMAT_LENGTH 10

//------- Private auxiliary functions -------//

int boardAllocationCheck(int **board, int width) {
    if (board == NULL)
        return 0;

    for (int i = 0; i < width; ++i)
        if (board[i] == NULL)
            return 0;

    return 1;
}

int **boardAlloc(int width, int height) {
    int **board =(int**) malloc(width * sizeof(int *));
    for (int i = 0; i < width; ++i)
        board[i] = (int*)calloc(height / BOARD_TYPE_LENGTH, sizeof(int));

    if (!boardAllocationCheck(board, width))
        return NULL;

    return board;
}

universe *makeUniverse(int width, int height) {
    universe *u = (universe*)malloc(sizeof(universe)); //Alloc space with size of our universe :)

    u->board = boardAlloc(width, height);

    if (u->board == NULL)
        return NULL;

    u->width = width;
    u->height = height;

    return u;
}

void boardRandom(universe *u, long seed) {
    srand(seed);

    int lives = seed % (u->width * u->height) / 4; //Divided by 4 to reduce number of alive cells

    for (int i = 0; i < lives; ++i) {
        int x = rand() % u->width;
        int y = rand() % u->height;

        setCell(u, x, y, LIFE);
    }
}

void boardLoadFromFile(universe *u, char *srcName) {
    FILE *src = fopen(srcName, "r");
	char format[FORMAT_LENGTH];
	char* line = (char*)malloc(sizeof(char) * (u->width + 2));
    sprintf(format, "%%%ds", u->width+1);
	
	for (int j = 0; j < u->height / BOARD_TYPE_LENGTH; ++j) {
		fscanf(src, format, line);

		for (int i = 0; i < u->width; ++i)
		{
			setCell(u, i, j, line[i] == DEAD_VISUAL ? DEAD : LIFE);
		}
    }
	fclose(src);
}

int validateValue(int value) {
    return value % 2; //to prevent low-level functions from mapping voulnerabilities
}



//------- Init/Dealloc functions -------//

universe *prepareUniverse(int width, int height) {
    universe *u = makeUniverse(width, height);
    boardRandom(u, 12345); //Constant seed for debugging purposes

    return u;
}

universe *prepareUniverseFromSource(int width, int height, char *srcName) {
    universe *u = makeUniverse(width, height);
    boardLoadFromFile(u, srcName);

    return u;
}


void destroyUniverse(universe *u) { //More epic function than 'freeBoard/1'
    for (int i = 0; i < u->height; ++i)
        free(u->board[i]);

    free(u->board);
    free(u);
}



//------- Fields navigation -------//

int getCell(universe *u, int xCoord, int yCoord) {
    int x = xCoord % u->width;
    int y = (yCoord % u->height) / BOARD_TYPE_LENGTH;

    if (u->board[x][y] & (1 << yCoord % BOARD_TYPE_LENGTH))
        return LIFE;
    else
        return DEAD;
}

void setCell(universe *u, int xCoord, int yCoord, int value) {
    int x = xCoord % u->width;
    int y = (yCoord % u->height) / BOARD_TYPE_LENGTH;
    value = validateValue(value);

    //C is beautiful, hacker-friendly language, I love it! I'll call it Stopyra's switch :)
    u->board[x][y] |= (value << yCoord % BOARD_TYPE_LENGTH);
    u->board[x][y] &= 0xffffffff & (value << yCoord % BOARD_TYPE_LENGTH);
}



//------- Output saving -------//

void saveToFile(universe *u, char *outName) {
    FILE *out = fopen(outName, "w");
	printf("%s\n", outName);
    for (int j = 0; j < u->height; ++j) {
        for (int i = 0; i < u->width; ++i)
            fprintf(out, "%c", getCell(u, i, j) == LIFE ? LIFE_VISUAL : DEAD_VISUAL);
        fprintf(out, "\n");
    }
    
    fclose(out);
}
