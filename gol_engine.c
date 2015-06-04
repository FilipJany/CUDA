// game_of_life.c
//
// Nvidia CUDA implementation of simultaneous game of life.
//
// Created by Filip Jany & Patryk Stopyra
// Wroclaw, 22.05.2015.

#include "gol_engine.h"

// PRIVATE

int boardAllocationCheck(int **board) {
    //checks if all of allocated vectors are not null
    //1 if it's ok, 0 otherwise
}

int **boardAlloc(int width, int height) {
    int **board = malloc(height * sizeof(int *));
    for (int i = 0; i < width % BOARD_TYPE_LENGTH; ++i)
        board[i] = calloc(width / BOARD_TYPE_LENGTH, sizeof(int));

    if (!boardAllocationCheck(board))
        return NULL;

    return board;
}

void boardRandom(int **board, long seed) {
    
}

void boardLoadFromFile(int **board, FILE src) {
    //TODO
}



// PUBLIC

int **prepareBoard(int width, int height) {
    int **board = boardAlloc(width, height);

    if (board == NULL)
        return NULL;

    //TODO invoke proper random seed
    boardRandom(board, 12345);

    return board;
}

int **prepareBoardFromSource(int width, int height, FILE src) {
    int **board = boardAlloc(width, height);

    if (board == NULL)
        return NULL;

    boardLoadFromFile(board, src);

    return board;
}

void freeBoard(int **board) {
    //TODO
}

