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
#define NO_LIFE ' '
#define LIFE '*'

int **prepareBoard(int width, int height);

int **prepareBoardFromSource(int width, int height, FILE src);

#endif /* defined(____gol_engine__) */
