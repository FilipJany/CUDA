#ifndef ____nvidia_engine__
#define ____nvidia_engine__

#include <cuda.h>

typedef struct
{
	int* tab_0;
	int* tab_1;
	int actual; //0 if tab_1, 1 if tab_2
}world;

__global__ void computeNextStep(world* w);
int getMooreNeighborhood(int* board_d, int hi, int wid);

world* copyArrayToDevice(universe uni);
void copyArrayToHost(world* w, universe* uni);

#endif