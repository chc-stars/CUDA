
#include "src/common/error.cuh"
#include "kernel.cuh"

// �����ӷ�

// ��Ŀ1�������ӷ�
// ����: ��дһ��CUDA����ʵ��������������Ԫ�ؼӷ���

// Ҫ��:

// ��ʼ��������СΪN������A��B��
// ʹ��CUDA�ں˺�������C = A + B��
// ��ӡ����������C��


int vecAdd_(float a[], float b[], float* c, size_t N) {

    // �����豸������ָ��
    float* d_a, * d_b, * d_c;

    // �����豸���ڴ�
    CHECK(cudaMalloc((void**)&d_a, N * sizeof(float)));
    CHECK(cudaMalloc((void**)&d_b, N * sizeof(float)));
    CHECK(cudaMalloc((void**)&d_c, N * sizeof(float)));

    // �����ݴ������˸��Ƶ��豸��
    CHECK(cudaMemcpy(d_a, a, N * sizeof(float), cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_b, b, N * sizeof(float), cudaMemcpyHostToDevice));

    // �����߳̿������Ĵ�С
    int blockSize = 256;
    int gridSize = (N + blockSize - 1) / blockSize;

    // ����CUDA�ں�
    vecAdd <<<gridSize, blockSize >>> (d_a, d_b, d_c, N);

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
