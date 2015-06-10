#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <cuda.h>
#include "gol_engine.h"
#include "nvidia_engine.h"


__device__ static int width;
__device__ static int height;


//------ Some computational functions ------//

int mod(int number, int modulus) {
	return abs(number % modulus);
}

__device__ void computeColumn(int index, world* w)
{

}

__global__ void computeNextStep(world* w)
{
	for (int i = 0; i < width / blockDim.x; ++i)
	{
		computeColumn(i*gridDim.x*blockDim.x*height / BOARD_TYPE_LENGTH
			+ threadIdx.x*height / BOARD_TYPE_LENGTH, w);
	}
	//printf("H: %d, W: %d\n", height, width);
}

int getMooreNeighborhood(int* board_d)
{
    int numNbrs = 0;
	
	//blockIdx.x * blockDim.x + threadIdx.x;
    //int x = (numer porzadkowy wierzcholka) / (height * BOARD_TYPE_LENGTH);
    //int y = ((numer porzadkowy wierzcholka) - x * (height * BOARD_TYPE_LENGTH));

    return numNbrs;
}

world* copyArrayToDevice(universe uni)
{
	world* w = (world*)malloc(sizeof(world));
	
	cudaMalloc((void**) &(w->tab_0), uni.height*uni.width / sizeof(int));
	cudaMalloc((void**) &(w->tab_1), uni.height*uni.width / sizeof(int));
	w->actual = 0;
	for(int i=0; i < uni.width; ++i)
	{
		cudaMemcpy(&(w->tab_0)+i*uni.height/BOARD_TYPE_LENGTH, uni.board[i], uni.height/BOARD_TYPE_LENGTH, cudaMemcpyHostToDevice);
	}

	cudaMemcpyToSymbol(width, &(uni.width),sizeof(int));
	cudaMemcpyToSymbol(height, &(uni.height), sizeof(int));

	return w;
}

void copyArrayToHost(world* w, universe* uni)
{
	for(int i = 0; i < uni->width; ++i)
	{
		if (!w->actual)
			cudaMemcpy(uni->board[i], &(w->tab_0)+i*uni->height/BOARD_TYPE_LENGTH, uni->height/BOARD_TYPE_LENGTH, cudaMemcpyDeviceToHost);
		else
			cudaMemcpy(uni->board[i], &(w->tab_1) + i*uni->height / BOARD_TYPE_LENGTH, uni->height / BOARD_TYPE_LENGTH, cudaMemcpyDeviceToHost);
	}
}
