#ifndef COMMON_H
#define COMMON_H

// Для CLOCK_MONOTONIC в Linux
#ifdef __linux__
#define _POSIX_C_SOURCE 199309L
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

// Для CLOCK_MONOTONIC в Linux
#ifdef __linux__
#include <unistd.h>
#endif

#pragma pack(push, 1)
typedef struct
{
    uint16_t signature;
    uint32_t file_size;
    uint16_t reserved1;
    uint16_t reserved2;
    uint32_t data_offset;
} BMPHeader;

typedef struct
{
    uint32_t header_size;
    int32_t width;
    int32_t height;
    uint16_t planes;
    uint16_t bits_per_pixel;
    uint32_t compression;
    uint32_t image_size;
    int32_t x_pixels_per_meter;
    int32_t y_pixels_per_meter;
    uint32_t colors_used;
    uint32_t colors_important;
} BMPInfoHeader;
#pragma pack(pop)

typedef struct
{
    uint8_t *data;
    int width;
    int height;
    int channels;
} Image;

// Общие функции для работы с BMP
int load_bmp(const char *filename, Image *img);
int save_bmp(const char *filename, const Image *img);
void free_image(Image *img);
double get_time_diff(struct timespec start, struct timespec end);

// Единая функция размытия (автоматический выбор реализации)
double gaussian_blur(const Image *input, Image *output);

// Внутренние функции реализации алгоритма (одинаковая сигнатура)
void gaussian_blur_c_impl(uint8_t *input, uint8_t *output, int width, int height);
extern void gaussian_blur_asm_impl(uint8_t *input, uint8_t *output, int width, int height);

#endif
