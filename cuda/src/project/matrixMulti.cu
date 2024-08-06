// 2������˷�

// ��Ŀ2������˷�
// ����: ��дһ��CUDA����ʵ����������ĳ˷���

// Ҫ��:

// ��ʼ��������СΪMxN��NxP�ľ���A��B��
// ʹ��CUDA�ں˺����������˷�C = A * B��
// ��ӡ����������C��

#include "src/common/error.cuh"
#include <cuda_runtime.h>
#include <iostream>
#include <device_launch_parameters.h>



__global__ void matrixMulti(float* a, float* b, float* c, int n) {
    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    if (idx < n) {
        c[idx] = a[idx] * b[idx];
    }
}


int runMatrixMulti(float a[], float b[], float c[], size_t N) {


    // �����豸������ָ��
    float* d_a, * d_b, * d_c;

    // �����豸���ڴ�
    CHECK(cudaMalloc((void**)&d_a, N * sizeof(float)));
    CHECK(cudaMalloc((void**)&d_b, N * sizeof(float)));
    CHECK(cudaMalloc((void**)&d_c, N * sizeof(float)));

    // ���ݿ������豸��
    CHECK(cudaMemcpy(d_a, a, N * sizeof(float), cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_b, b, N * sizeof(float), cudaMemcpyHostToDevice));

    // �����߳̿������Ĵ�С
    int blockSize = 256;
    int gridSize = (N + blockSize - 1) / blockSize;

    // ����CUDA�ں�
    matrixMulti << <gridSize, blockSize >> > (d_a, d_b, d_c, N);

    // ͬ���豸��
    CHECK(cudaDeviceSynchronize());

    // ��������豸�˸��Ƶ�������
    CHECK(cudaMemcpy(c, d_c, N * sizeof(float), cudaMemcpyDeviceToHost));

    // �ͷ��豸���ڴ�
    CHECK(cudaFree(d_a));
    CHECK(cudaFree(d_b));
    CHECK(cudaFree(d_c));

    // ��ӡ���
    for (int i = 0; i < N; ++i) {
        printf("c[%d] = %f\n", i, c[i]);
    }

    return 0;

}

