#ifndef ____nvidia_engine__
#define ____nvidia_engine__

#include <cuda.h>


__global__ void computeNextStep(int* tab_0, int* tab_1, int actual);
__global__ void computeNextStepSharedMemory(int* tab_0, int* tab_1, int actual);

void copyArrayToDevice(universe uni, int* tab_0);
void copyArrayToHost(universe* uni, int* tab_0, int* tab_1, int actual);

#endif