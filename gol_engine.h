// game_of_life.c
//
// Nvidia CUDA implementation of simultaneous game of life.
//
// Created by Filip Jany & Patryk Stopyra
// Wroclaw, 22.05.2015.

#ifndef ____gol_engine__
#define ____gol_engine__

#include <stdio.h>
#include <stdlib.h>

#define BOARD_TYPE_LENGTH 32

#define LIFE 1
#define DEAD 0

#define DEAD_VISUAL ' '
#define LIFE_VISUAL '*'

typedef struct {
    int **board;
    int width;
    int height;
} universe;

universe *prepareUniverse(int width, int height);

universe *prepareUniverseFromSource(int width, int height, char *srcName);

void saveToFile(universe *u, char *outName);

void destroyUniverse(universe *u);

int getCell(universe *u, int xCoord, int yCoord);

void setCell(universe *u, int xCoord, int yCoord, int value);

#endif /* defined(____gol_engine__) */
