#ifndef ____nvidia_engine__
#define ____nvidia_engine__

#include <cuda.h>

__global__ void computeNextStep(int* board_d);
int getMooreNeighborhood(int* board_d, int hi, int wid);

int* copyArrayToDevice(universe uni);
void copyArrayToHost(int* board_d, universe uni);

#endif