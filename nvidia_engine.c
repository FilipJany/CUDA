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
	int width = uni.width; //number of int's in array -> width
	int* board_d;
	cudaMalloc((void**)&board_d, uni.height*uni.width/sizeof(int));
	
	for(int i=0; i < uni.width; ++i)
	{
		cudaMemcpy(board_d+i*height/BOARD_TYPE_LENGTH, uni.board[i], uni.height/BOARD_TYPE_LENGTH, cudaMemcpyHostToDevice);
	}
	return board_d;
}

void copyArrayToHost(int* board_d, universe uni)
{
	for(int i = 0; i < uni.width; ++i)
	{
		cudaMemcpy(uni.board[i], board_d+i*height/BOARD_TYPE_LENGTH, uni.height/BOARD_TYPE_LENGTH, cudaMemcpyDeviceToHost);
	}
}
