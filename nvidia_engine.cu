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
		//printf("left: %d, mid: %d, right: %d\n", left, mid, right);
		int j = i - 1;
		int k = i + 1;

		int sum = (left & (1 << j) ? 1 : 0)
			+ (left & (1 << i) ? 1 : 0)
			+ (left & (1 << k) ? 1 : 0)
			+ (mid & (1 << j) ? 1 : 0)
			+ (mid & (1 << k) ? 1 : 0)
			+ (right & (1 << j) ? 1 : 0)
			+ (right & (1 << i) ? 1 : 0)
			+ (right & (1 << k) ? 1 : 0);
		//if (blockIdx.x > 9 && blockIdx.x < 14)
			//printf("%d\t", sum);
		if (mid & (1 << i)) {
			if (sum == 2 || sum == 3) {
				result = result | (1 << i);
			}
		}
		else {
			
			if (sum == 3) {
				//printf("aliveCMC: %d\n", mid);
				result = result | (1 << i);
			}
		}
		
	}
	//printf("RESA: %d\n", result);
	return result;
}

__device__ void computeColumn(int index, int* tab_0, int* tab_1, int actual)
{
	//printf("index: %d\n", index);
	//printf("w: %d\n", width);
	//printf("h: %d\n", height);

	if (threadIdx.x >= height / BOARD_TYPE_LENGTH)
	{
		//printf("In return Index: %d\n", index);
		return;
	}
	//printf("bd: %d\n", blockDim.x);
	//printf("h: %d\n", height);
	//printf("btl: %d\n", BOARD_TYPE_LENGTH);
	//printf("diff: %d\n", (height / BOARD_TYPE_LENGTH) / blockDim.x);

	int left[3];
	int mid[3];
	int right[3];
	//printf("ACT: %d\n", actual);
	int *board = (actual ? tab_1 : tab_0);
	//printf("B: %d\n", board);
	//printf("t0: %d\n", tab_0);
	//printf("t1: %d\n", tab_1);
	//printf("2\n");
	int upperBound = (height / BOARD_TYPE_LENGTH) / blockDim.x;
	//printf("ub: %d\n", upperBound);
	for (int dupa = 0; dupa < upperBound; ++dupa) {
		//printf("DUPA: %d\n", dupa);
		int col = mod(index - (height / BOARD_TYPE_LENGTH), size);
		//printf("col left: %d\n", col);

		//printf("L0: %d\n", col + mod(dupa*blockDim.x + threadIdx.x - 1, (height / BOARD_TYPE_LENGTH)));
		left[0] = board[col + mod(dupa*blockDim.x + threadIdx.x - 1, (height / BOARD_TYPE_LENGTH))];
		//printf("L1: %d\n", col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH)));
		left[1] = board[col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH))];
		//printf("L2: %d\n", col + mod(dupa*blockDim.x + threadIdx.x + 1, (height / BOARD_TYPE_LENGTH)));
		left[2] = board[col + mod(dupa*blockDim.x + threadIdx.x + 1, (height / BOARD_TYPE_LENGTH))];

		col = index;
		//printf("col mid: %d\n", col);
		mid[0] = board[col + mod(dupa*blockDim.x + threadIdx.x - 1, (height / BOARD_TYPE_LENGTH))];
		mid[1] = board[col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH))];
		//printf("%d\n", col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH)));
		//if (mid[1] != 0)
		//	printf("m1: %d\n", mid[1]);
		mid[2] = board[col + mod(dupa*blockDim.x + threadIdx.x + 1, (height / BOARD_TYPE_LENGTH))];
		
		col = mod(index + (height / BOARD_TYPE_LENGTH), size);
		//printf("col right: %d\n", col);
		right[0] = board[col + mod(dupa*blockDim.x + threadIdx.x - 1, (height / BOARD_TYPE_LENGTH))];
		right[1] = board[col + mod(dupa*blockDim.x + threadIdx.x, (height / BOARD_TYPE_LENGTH))];
		right[2] = board[col + mod(dupa*blockDim.x + threadIdx.x + 1, (height / BOARD_TYPE_LENGTH))];
		
		//printf("data gathered index: %d\n", index);

		int result = computeMidCells(left[1], mid[1], right[1]);

		//printf("computed mid cells index: %d\n", index);

		int sum = (left[0] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0)
			+ (left[1] & 1 ? 1 : 0)
			+ (left[1] & (1 << 1) ? 1 : 0)
			+ (mid[0] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0)
			+ (mid[1] & (1 << 1) ? 1 : 0)
			+ (right[0] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0)
			+ (right[1] & 1 ? 1 : 0)
			+ (right[1] & (1 << 1) ? 1 : 0);

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
		//printf("Summ for index: %d = %d\n", index, sum);
		sum = (left[1] & (1 << BOARD_TYPE_LENGTH - 2) ? 1 : 0)
			+ (left[1] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0)
			+ (left[2] & 1 ? 1 : 0)
			+ (mid[1] & (1 << BOARD_TYPE_LENGTH - 2) ? 1 : 0)
			+ (mid[2] & 1 ? 1 : 0)
			+ (right[1] & (1 << BOARD_TYPE_LENGTH - 2) ? 1 : 0)
			+ (right[1] & (1 << BOARD_TYPE_LENGTH - 1) ? 1 : 0)
			+ (right[2] & 1 ? 1 : 0);

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

		if (actual) {
			tab_0[index + dupa*blockDim.x + threadIdx.x] = result;
			//printf("tab0[%d] = %d\n", index + dupa*blockDim.x + threadIdx.x, tab_0[index + dupa*blockDim.x + threadIdx.x]);
		}
		else {
			tab_1[index + dupa*blockDim.x + threadIdx.x] = result;
			//printf("tab1[%d] = %d\n", index + dupa*blockDim.x + threadIdx.x, tab_1[index + dupa*blockDim.x + threadIdx.x]);
		}
		//printf("[%d], [%d]: %d\n", blockIdx.x, threadIdx.x, result);
	}
}

__global__ void computeNextStep(int* tab_0, int* tab_1, int actual)
{
	for (int i = 0; i < width / gridDim.x; ++i) //ASSERT : width % gridDim.x = 0
	{
		computeColumn(i*gridDim.x*(height / BOARD_TYPE_LENGTH)
			+ blockIdx.x*(height / BOARD_TYPE_LENGTH), tab_0, tab_1, actual);
	}
	//printf("H: %d, W: %d\n", height, width);
}

void copyArrayToDevice(universe uni, int* tab_0)
{
	for (int i = 0; i < uni.width; ++i)
	{
		cudaMemcpy((tab_0)+i*(uni.height / BOARD_TYPE_LENGTH), uni.board[i], (uni.height / BOARD_TYPE_LENGTH) * sizeof(int), cudaMemcpyHostToDevice);
	}

	cudaMemcpyToSymbol(width, &(uni.width), sizeof(int));
	cudaMemcpyToSymbol(height, &(uni.height), sizeof(int));
	int sizeHost = (uni.width * uni.height) / BOARD_TYPE_LENGTH;
	cudaMemcpyToSymbol(size, &sizeHost, sizeof(int));
	//for (int i = 0; i < uni.width; ++i)
	//{
		//printf("ub[%d] - tab[%d]\n", uni.board[i][0], tab_0[i]);
	//}
}

void copyArrayToHost(universe* uni, int* tab_0, int* tab_1, int actual)
{
	for (int i = 0; i < uni->width; ++i)
	{
		if (!actual)
			cudaMemcpy(uni->board[i], tab_0+i*uni->height / BOARD_TYPE_LENGTH, (uni->height / BOARD_TYPE_LENGTH) * sizeof(int), cudaMemcpyDeviceToHost);
		else
			cudaMemcpy(uni->board[i], tab_1+i*uni->height / BOARD_TYPE_LENGTH, (uni->height / BOARD_TYPE_LENGTH) * sizeof(int), cudaMemcpyDeviceToHost);
	}
}
