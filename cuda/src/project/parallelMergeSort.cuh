#include <vector>

#include <cuda_runtime.h>
#include <iostream>
#include <algorithm>
#include <math.h>

std::vector<int> runParallelMergeSort(std::vector<int> arr);


// ******************   ����  ****************


//int size = 99040;  ���������С
//std::vector<int> arr(size);  
//
//std::vector<int> rg = runParallelMergeSort(arr);