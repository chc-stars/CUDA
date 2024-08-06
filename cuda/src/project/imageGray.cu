
// ��Ŀ4��ͼ��ҶȻ�
// ����: ��дһ��CUDA���򣬽�һ��RGBͼ��ת��Ϊ�Ҷ�ͼ��

// Ҫ��:

// ��ʼ��һ��MxNx3��RGBͼ��
// ʹ��CUDA�ں˺�������Ҷ�ͼ�񣬻Ҷ�ֵ���㹫ʽΪGray = 0.299R + 0.587G + 0.114*B��
// ��ӡ�������Ҷ�ͼ��
#include <cuda_runtime.h>
#include <iostream>
#include <chrono>
#include "device_launch_parameters.h"

// Time to run on CPU: 5381.61 ms
// Gray Image (CPU):
// Time to run kernel: 7.72288 ms
// Gray Image (GPU):

#define M 2600 // ͼ��߶�
#define N 2600 // ͼ����

__global__ void rgb2gray(unsigned char* rgb, unsigned char* gray, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int idx = y * width + x;

    if (x < width && y < height) {
        unsigned char r = rgb[3 * idx];
        unsigned char g = rgb[3 * idx + 1];
        unsigned char b = rgb[3 * idx + 2];
        gray[idx] = 0.299f * r + 0.587f * g + 0.114f * b;
    }
}

void initializeImage(unsigned char* image, int width, int height) {
    for (int i = 0; i < width * height * 3; i++) {
        image[i] = rand() % 256; // �����ʼ��ͼ������
    }
}

void printImage(unsigned char* image, int width, int height, int channels) {
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            for (int k = 0; k < channels; k++) {
                printf("%d ", image[(i * width + j) * channels + k]);
            }
            printf(" | ");
        }
        printf("\n");
    }
}

void rgb2grayCPU(unsigned char* rgb, unsigned char* gray, int width, int height) {
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int idx = y * width + x;
            unsigned char r = rgb[3 * idx];
            unsigned char g = rgb[3 * idx + 1];
            unsigned char b = rgb[3 * idx + 2];
            gray[idx] = 0.299f * r + 0.587f * g + 0.114f * b;
        }
    }
}

int runImgGray() {
    int width = N;
    int height = M;
    size_t rgb_size = width * height * 3 * sizeof(unsigned char);
    size_t gray_size = width * height * sizeof(unsigned char);

    // ���������ڴ�
    unsigned char* h_rgb = (unsigned char*)malloc(rgb_size);
    unsigned char* h_gray = (unsigned char*)malloc(gray_size);
    unsigned char* h_gray_cpu = (unsigned char*)malloc(gray_size);

    // ��ʼ��RGBͼ��
    initializeImage(h_rgb, width, height);

    // ��ӡRGBͼ��
    std::cout << "RGB Image:\n";
    // printImage(h_rgb, width, height, 3);

    // CPU ����Ҷ�ͼ�񲢲���ʱ��
    auto start_cpu = std::chrono::high_resolution_clock::now();
    rgb2grayCPU(h_rgb, h_gray_cpu, width, height);
    auto stop_cpu = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float, std::milli> duration_cpu = stop_cpu - start_cpu;
    std::cout << "Time to run on CPU: " << duration_cpu.count() << " ms" << std::endl;

    // ��ӡ�Ҷ�ͼ��CPU ��������
    std::cout << "Gray Image (CPU):\n";
    // printImage(h_gray_cpu, width, height, 1);

    // �����豸�ڴ�
    unsigned char* d_rgb, * d_gray;
    cudaMalloc((void**)&d_rgb, rgb_size);
    cudaMalloc((void**)&d_gray, gray_size);

    // �������ݵ��豸
    cudaMemcpy(d_rgb, h_rgb, rgb_size, cudaMemcpyHostToDevice);

    // �����������С
    dim3 blockSize(16, 16);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);

    // ����CUDA�¼�
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // ��¼��ʼ�¼�
    cudaEventRecord(start, 0);

    // ����CUDA�ں�
    rgb2gray << <gridSize, blockSize >> > (d_rgb, d_gray, width, height);

    // ��¼�����¼�
    cudaEventRecord(stop, 0);

    // ͬ���¼�
    cudaEventSynchronize(stop);

    // ����ʱ���
    float elapsedTime;
    cudaEventElapsedTime(&elapsedTime, start, stop);
    std::cout << "Time to run kernel: " << elapsedTime << " ms" << std::endl;

    // �����Ҷ�ͼ�����ݻ�����
    cudaMemcpy(h_gray, d_gray, gray_size, cudaMemcpyDeviceToHost);

    // ��ӡ�Ҷ�ͼ��
    std::cout << "Gray Image (GPU):\n";
    // printImage(h_gray, width, height, 1);

    // �ͷ�CUDA�¼�
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    // �ͷ��豸�ڴ�
    cudaFree(d_rgb);
    cudaFree(d_gray);

    // �ͷ������ڴ�
    free(h_rgb);
    free(h_gray);
    free(h_gray_cpu);

    return 0;
}
