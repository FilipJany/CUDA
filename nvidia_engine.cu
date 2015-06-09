#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <cuda.h>
#include "gol_engine.h"
#include "nvidia_engine.h"


static int width;
static int height;


//------ Some computational functions ------//

int mod(int number, int modulus) {
	return abs(number % modulus);
}

void computeNextStep(int* board_d)
{
	//do the magic
}

__global__ int getMooreNeighborhood(int* board_d)
{
    int numNbrs = 0;

    int x = (numer porzadkowy wierzcholka) / (height * BOARD_TYPE_LENGTH);
    int y = ((numer porzadkowy wierzcholka) - x * (height * BOARD_TYPE_LENGTH));

    return numNbrs;
}

int* copyArrayToDevice(universe uni)
{
	int width = uni.width; //number of int's in array -> width
	int* board_d;
	cudaMalloc((void**)&board_d, uni.height*uni.width/sizeof(int));
	
	for(int i=0; i < uni.width; ++i)
	{
		cudaMemcpy(board_d+i*uni.height/BOARD_TYPE_LENGTH, uni.board[i], uni.height/BOARD_TYPE_LENGTH, cudaMemcpyHostToDevice);
	}
	width = uni.width;
	height = uni.height;
	return board_d;
}

void copyArrayToHost(int* board_d, universe uni)
{
	for(int i = 0; i < uni.width; ++i)
	{
		cudaMemcpy(uni.board[i], board_d+i*uni.height/BOARD_TYPE_LENGTH, uni.height/BOARD_TYPE_LENGTH, cudaMemcpyDeviceToHost);
	}
}
