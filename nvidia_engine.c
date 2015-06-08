#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gol_engine.h"
#include "nvidia_engine.h"


__global__ void computeNextStep(int* board_d)
{
	//do the magic
}

__global__ int* getMooreNeighborhood(int* board_d, int cell)
{
	//do the other magic 
}

int* copyArrayToDevice(universe uni)
{
	int width = uni.width / BOARD_TYPE_LENGTH; //number of int's in array -> width
	int* board_d;
	cudaMalloc((void**)&board_d, uni.height*width*sizeof(int))

	cudaMemcpy(board_d, uni.board, uni.height*width*sizeof(int), cudaMemcpyHostToDevice);
	return board_d;
}

void copyArrayToHost(int* board_d, universe uni)
{
	int width = uni.width / BOARD_TYPE_LENGTH;
	int* copied = (int*)calloc(uni.height*width*sizeof(int))
	cudaMemcpy(copied, board_d, uni.height*width*sizeof(int), cudaMemcpyDeviceToHost);
	//copy data from 1d array to 2d
	int i = 0;
	int j = 0;
	int iter = 0;
	while(iter < width*uni.height)
	{
		uni.board[i][j] = copied[iter];
		++i;
		++iter;
		if(iter % width == 0)
		{
			i = 0;
			j++;
		}
	}
	free(copied);
}
