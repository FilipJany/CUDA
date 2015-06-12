#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <cuda.h>
#include "gol_engine.h"
#include "nvidia_engine.h"


__device__ static int width;
__device__ static int height;
__device__ static int size;


//------ Some computational functions ------//

__device__ int mod(int number, int modulus) {
	if (number % modulus >= 0)
		return number % modulus;
	else
		return modulus + (number % modulus);
}

__device__ int computeMidCells(int left, int mid, int right) {
	int result = 0;

	for (int i = 1; i < BOARD_TYPE_LENGTH - 1; ++i) {
		printf("left: %d, mid: %d, right: %d\n", left, mid, right);
		int j = i - 1;
		int k = i + 1;

		int sum = left & (1 << j) ? 1 : 0
			+ left & (1 << i) ? 1 : 0
			+ left & (1 << k) ? 1 : 0
			+ mid & (1 << j) ? 1 : 0
			+ mid & (1 << k) ? 1 : 0
			+ right & (1 << j) ? 1 : 0
			+ right & (1 << i) ? 1 : 0
			+ right & (1 << k) ? 1 : 0;

		if (mid & (1 << i)) {
			if (sum == 2 || sum == 3) {
				result = result | (1 << i);
			}
		}
		else {
			if (sum == 3) {
				result = result | (1 << i);
			}
		}
	}

	return result;
}

__device__ void computeColumn(int index, world* w)
{
	printf("index: %d\n", index);
	if (threadIdx.x >= height / BOARD_TYPE_LENGTH)
	{
		printf("In return Index: %d\n", index);
		return;
	}
	//printf("bd: %d\n", blockDim.x);
	//printf("h: %d\n", height);
	//printf("btl: %d\n", BOARD_TYPE_LENGTH);
	//printf("diff: %d\n", (height / BOARD_TYPE_LENGTH) / blockDim.x);

	int left[3];
	int mid[3];
	int right[3];
	printf("1\n");
	int *board = w->actual ? w->tab_1 : w->tab_0;
	printf("2\n");
	int upperBound = (height / BOARD_TYPE_LENGTH) / blockDim.x;
	printf("ub: %d\n", upperBound);
	for (int dupa = 0; dupa < upperBound; ++dupa) {
		printf("DUPA: %d\n", dupa);
		int col = mod(index - (height / BOARD_TYPE_LENGTH), size);
		left[0] = board[col + mod(dupa*blockDim.x + threadIdx.x - 1, (height / BOARD_TYPE_LENGTH))];
		left[1] = board[col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH))];
		left[2] = board[col + mod(dupa*blockDim.x + threadIdx.x + 1, (height / BOARD_TYPE_LENGTH))];

		col = index;
		mid[0] = board[col + mod(dupa*blockDim.x + threadIdx.x - 1, (height / BOARD_TYPE_LENGTH))];
		mid[1] = board[col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH))];
		mid[2] = board[col + mod(dupa*blockDim.x + threadIdx.x + 1, (height / BOARD_TYPE_LENGTH))];

		col = mod(index + (height / BOARD_TYPE_LENGTH), size);
		right[0] = board[col + mod(dupa*blockDim.x + threadIdx.x - 1, (height / BOARD_TYPE_LENGTH))];
		right[1] = board[col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH))];
		right[2] = board[col + mod(dupa*blockDim.x + threadIdx.x + 1, (height / BOARD_TYPE_LENGTH))];

		printf("data gathered index: %d\n", index);

		int result = computeMidCells(left[1], mid[1], right[1]);

		printf("computed mid cells index: %d\n", index);

		int sum = left[0] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0
			+ left[1] & 1 ? 1 : 0
			+ left[1] & (1 << 1) ? 1 : 0
			+ mid[0] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0
			+ mid[1] & (1 << 1) ? 1 : 0
			+ right[0] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0
			+ right[1] & 1 ? 1 : 0
			+ right[1] & (1 << 1) ? 1 : 0;

		if (mid[1] & 1) {
			if (sum == 2 || sum == 3) {
				result = result | 1;
			}
		}
		else {
			if (sum == 3) {
				result = result | 1;
			}
		}
		printf("Summ for index: %d = %d\n", index, sum);
		sum = left[1] & (1 << BOARD_TYPE_LENGTH - 2) ? 1 : 0
			+ left[1] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0
			+ left[2] & 1 ? 1 : 0
			+ mid[1] & (1 << BOARD_TYPE_LENGTH - 2) ? 1 : 0
			+ mid[2] & 1 ? 1 : 0
			+ right[1] & (1 << BOARD_TYPE_LENGTH - 2) ? 1 : 0
			+ right[1] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0
			+ right[2] & 1 ? 1 : 0;

		if (mid[1] & (1 << BOARD_TYPE_LENGTH - 1)) {
			if (sum == 2 || sum == 3) {
				result = result | (1 << BOARD_TYPE_LENGTH - 1);
			}
		}
		else {
			if (sum == 3) {
				result = result | (1 << BOARD_TYPE_LENGTH - 1);
			}
		}

		if (w->actual) {
			w->tab_0[index + dupa*blockDim.x + threadIdx.x] = result;
		}
		else {
			w->tab_1[index + dupa*blockDim.x + threadIdx.x] = result;
		}
		printf("[%d], [%d]: \n", blockIdx.x, threadIdx.x, result);
	}
}

__global__ void computeNextStep(world* w)
{
	for (int i = 0; i < width / gridDim.x; ++i) //ASSERT : width % gridDim.x = 0
	{
		computeColumn(i*gridDim.x*(height / BOARD_TYPE_LENGTH)
			+ blockIdx.x*(height / BOARD_TYPE_LENGTH), w);
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
	cudaMalloc((void**)&(w->tab_0), uni.height*uni.width / sizeof(int));
	cudaMalloc((void**)&(w->tab_1), uni.height*uni.width / sizeof(int));
	w->actual = 0;
	for (int i = 0; i < uni.width; ++i)
	{
		cudaMemcpy(&(w->tab_0) + i*uni.height / BOARD_TYPE_LENGTH, uni.board[i], uni.height / BOARD_TYPE_LENGTH, cudaMemcpyHostToDevice);
	}

	cudaMemcpyToSymbol(width, &(uni.width), sizeof(int));
	cudaMemcpyToSymbol(height, &(uni.height), sizeof(int));
	int sizeHost = (uni.width * uni.height) / BOARD_TYPE_LENGTH;
	cudaMemcpyToSymbol(size, &sizeHost, sizeof(int));

	return w;
}

void copyArrayToHost(world* w, universe* uni)
{
	for (int i = 0; i < uni->width; ++i)
	{
		if (!w->actual)
			cudaMemcpy(uni->board[i], &(w->tab_0) + i*uni->height / BOARD_TYPE_LENGTH, uni->height / BOARD_TYPE_LENGTH, cudaMemcpyDeviceToHost);
		else
			cudaMemcpy(uni->board[i], &(w->tab_1) + i*uni->height / BOARD_TYPE_LENGTH, uni->height / BOARD_TYPE_LENGTH, cudaMemcpyDeviceToHost);
	}
}