// game_of_life.c
//
// Nvidia CUDA implementation of simultaneous game of life.
//
// Created by Filip Jany & Patryk Stopyra
// Wroclaw, 22.05.2015.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gol_engine.h"

#define PARAMS_NUMBER 6

typedef struct {
    int width;
    int height;
    int startTry;
    int endTry;
    char *path;
} params;

params parseParams(int argc, char **argv) {
    params p;

    sscanf(argv[1], "%d", &(p.width));

    sscanf(argv[2], "%d", &(p.height));
    sscanf(argv[3], "%d", &(p.startTry));
    sscanf(argv[4], "%d", &(p.endTry));

    p.path = malloc((strlen(argv[5])+1) * sizeof(char));
    strncpy(p.path, argv[5], strlen(argv[5]));

    return p;
}

int validateParams(params p) {
    if (p.width % BOARD_TYPE_LENGTH != 0) {
        printf("[ERROR] Width has to be a multiplication of 32.\n");
        return 0;
    }

    return 1;
}

void userInfo() {
    printf("Proper usage:\n\tgame_of_life [width] [height] [start] [end] [path]\n");
    printf("where:\n");
    printf("\twidth - width of torus field\n");
    printf("\theight - height of torus field\n");
    printf("\tstart - round of recording begin\n");
    printf("\tend - round of recording stop\n");
    printf("\tpath - destination of recorded rounds\n");
}

int main(int argc, char **argv) {
    if (argc != PARAMS_NUMBER) {
        userInfo();
        return 1;
    }

    params p = parseParams(argc, argv);
    if (!validateParams(p))
        return 2;


    printf("%d %d %d %d %s\n", p.width, p.height, p.startTry, p.endTry, p.path);

    return 0;
}