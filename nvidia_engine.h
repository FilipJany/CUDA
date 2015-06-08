#ifndef ____nvidia_engine__
#define ____nvidia_engine__

__global__ void computeNextStep(int* board_d);
__global__ int* getMooreNeighborhood(int* board_d, int cell);

int* copyArrayToDevice(universe uni);
void copyArrayToHost(int* board_d, universe uni);

#endif