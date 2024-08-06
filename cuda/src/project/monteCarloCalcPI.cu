// 6�����ؿ��޼���pI

// ��Ŀ6�����ؿ��޷��������ֵ
// ����: ��дһ��CUDA����ʹ�����ؿ��޷�������е�ֵ��

// Ҫ��:

// ��ʼ��һ����СΪN�����飬���ڴ洢����㡣
// ʹ��CUDA�ں˺��������ڵ�λԲ�ڵĵ��������
// ���㲢��ӡ����еĽ���ֵ��

#include <cuda_runtime.h>
#include "src/common/error.cuh"
#include <iostream>
#include <curand_kernel.h>
#include <device_launch_parameters.h>

#define N 1000
#define BLOCK_SIZE 256

__global__ void monteCarloPiKernel(int* count, unsigned int seed) {

    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    curandState state;

    curand_init(seed, idx, 0, &state);

    float x = curand_uniform(&state);
    float y = curand_uniform(&state);

    if (x * x + y * y <= 1.0f) {
        atomicAdd(count, 1);
    }

}


void calculatePi() {

    int* d_count;
    int h_count = 0;

    CHECK(cudaMalloc(&d_count, sizeof(int)));
    CHECK(cudaMemcpy(d_count, &h_count, sizeof(int), cudaMemcpyHostToDevice));

    int gridSize = (N + BLOCK_SIZE - 1) / BLOCK_SIZE;

    cudaEvent_t start, end;
    cudaEventCreate(&start);
    cudaEventCreate(&end);

    cudaEventRecord(start, 0);
    monteCarloPiKernel << <gridSize, BLOCK_SIZE >> > (d_count, time(NULL));
    CHECK(cudaDeviceSynchronize());

    cudaEventRecord(end, 0);
    cudaEventSynchronize(end);
    float elaspedTime;
    cudaEventElapsedTime(&elaspedTime, start, end);

    std::cout << "Time: " << elaspedTime << std::endl;

    CHECK(cudaMemcpy(&h_count, d_count, sizeof(int), cudaMemcpyDeviceToHost));
    CHECK(cudaFree(d_count));

    float pi = 4.0f * h_count / N;
    std::cout << "Estimated Pi = " << pi << std::endl;
}

int runCalculatePi() {
    calculatePi();
    return 0;
}