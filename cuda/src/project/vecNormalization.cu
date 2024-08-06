// // 3. ������һ��

// ��Ŀ3��������һ��
// ����: ��дһ��CUDA����ʵ�������Ĺ�һ��������������ÿ��Ԫ�س��������ĳ��ȣ���

// Ҫ��:

// ��ʼ��һ����СΪN������A��
// ʹ��CUDA�ں˺��������һ������B��ʹ��B[i] = A[i] / ||A||������||A||������A��ŷ����÷�������
// ��ӡ����������B��

#include <cuda_runtime.h>
#include "src/common/error.cuh"
#include <iostream>
#include <cmath>
#include <device_launch_parameters.h>



__global__ void vecNorm(const float* a, float* b, int n) {
    __shared__ float sum[256]; // �����ڴ�����
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    int tid = threadIdx.x;

    // ����ÿ��Ԫ�ص�ƽ��
    sum[tid] = (idx < n) ? a[idx] * a[idx] : 0.0f;

    __syncthreads();

    // ��Լ���
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (tid < stride) {
            sum[tid] += sum[tid + stride];
        }
        __syncthreads();
    }

    // ����Լ���д��ȫ���ڴ�
    if (tid == 0) {
        atomicAdd(&b[0], sum[0]);
    }
}

__global__ void normalize(float* a, float* b, float norm, int n) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx < n) {
        b[idx] = a[idx] / norm;
    }
}

int runVecNormalization(float a[], float b[],  int N) {
 
    float h_sum = 0.0f;
  

    float* d_a, * d_b;

    // �����ڴ�
    CHECK(cudaMalloc((void**)&d_a, N * sizeof(float)));
    CHECK(cudaMalloc((void**)&d_b, N * sizeof(float)));

    // copy����
    CHECK(cudaMemcpy(d_a, a, N * sizeof(float), cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_b, &h_sum, sizeof(float), cudaMemcpyHostToDevice));

    // ����block
    int blockSize = 256;
    int gridSize = (N + blockSize - 1) / blockSize;

    // �����ں˼���������С
    vecNorm << <gridSize, blockSize >> > (d_a, d_b, N);
    CHECK(cudaDeviceSynchronize());

    // ��ƽ���ʹ��豸���Ƶ�����
    CHECK(cudaMemcpy(&h_sum, d_b, sizeof(float), cudaMemcpyDeviceToHost));

    // ����������L2����
    float norm = sqrt(h_sum);

    // ��һ������
    normalize << <gridSize, blockSize >> > (d_a, d_a, norm, N);
    CHECK(cudaDeviceSynchronize());

    // ��������豸���Ƶ�����
    CHECK(cudaMemcpy(b, d_a, N * sizeof(float), cudaMemcpyDeviceToHost));

    // �ͷ��豸�ڴ�
    CHECK(cudaFree(d_a));
    CHECK(cudaFree(d_b));

    // ��ӡ���
    for (int i = 0; i < N; i++) {
        printf("b[%d] = %f\n", i, b[i]);
    }

    return 0;
}
