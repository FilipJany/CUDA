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
extern __shared__ int sharedArray[];


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

__device__ void computeColumnSharedMemory(int index, int* tab, int* sharedArray, int actual)
{
	if (threadIdx.x >= height / BOARD_TYPE_LENGTH)
	{
		return;
	}

	int left[3];
	int mid[3];
	int right[3];
	int *board = sharedArray;

	int upperBound = (height / BOARD_TYPE_LENGTH) / blockDim.x;
	for (int dupa = 0; dupa < upperBound; ++dupa) {

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

		int result = computeMidCells(left[1], mid[1], right[1]);
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

		tab[index + dupa*blockDim.x + threadIdx.x] = result;
		
	}
}

__global__ void computeNextStepSharedMemory(int* tab_0, int* tab_1, int actual)
{
	int *board = (actual ? tab_0 : tab_1);
	for (int i = 0; i < width; ++i)
	{
		for (int j = 0; j < (height / BOARD_TYPE_LENGTH); ++j)
		{
			if (actual)
			{
				sharedArray[i*(height / BOARD_TYPE_LENGTH) + j] = tab_1[i*(height / BOARD_TYPE_LENGTH) + j];
			}
			else
			{
				sharedArray[i*(height / BOARD_TYPE_LENGTH) + j] = tab_0[i*(height / BOARD_TYPE_LENGTH) + j];
			}
		}
	}
	for (int i = 0; i < width / gridDim.x; ++i) //ASSERT : width % gridDim.x = 0
	{
		computeColumnSharedMemory(i*gridDim.x*(height / BOARD_TYPE_LENGTH)
			+ blockIdx.x*(height / BOARD_TYPE_LENGTH), board, sharedArray, actual);
	}
	__syncthreads();
}

__device__ void computeColumn(int index, int* tab_0, int* tab_1, int actual)
{
	if (threadIdx.x >= height / BOARD_TYPE_LENGTH)
	{
		return;
	}
	
	int left[3];
	int mid[3];
	int right[3];
	
	int *board = (actual ? tab_1 : tab_0);
	
	int upperBound = (height / BOARD_TYPE_LENGTH) / blockDim.x;
	
	for (int dupa = 0; dupa < upperBound; ++dupa) {
		
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
		
		int result = computeMidCells(left[1], mid[1], right[1]);
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
		}
		else {
			tab_1[index + dupa*blockDim.x + threadIdx.x] = result;
		}
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
