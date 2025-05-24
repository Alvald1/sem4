#include "common.h"

int load_bmp(const char *filename, Image *img)
{
    FILE *file = fopen(filename, "rb");
    if (!file)
    {
        printf("Ошибка: не удалось открыть файл %s\n", filename);
        return 0;
    }

    BMPHeader header;
    BMPInfoHeader info_header;

    if (fread(&header, sizeof(BMPHeader), 1, file) != 1)
    {
        printf("Ошибка чтения заголовка BMP\n");
        fclose(file);
        return 0;
    }

    if (header.signature != 0x4D42)
    {
        printf("Ошибка: файл не является BMP\n");
        fclose(file);
        return 0;
    }

    if (fread(&info_header, sizeof(BMPInfoHeader), 1, file) != 1)
    {
        printf("Ошибка чтения информационного заголовка\n");
        fclose(file);
        return 0;
    }

    if (info_header.bits_per_pixel != 24)
    {
        printf("Ошибка: поддерживаются только 24-битные BMP\n");
        fclose(file);
        return 0;
    }

    img->width = info_header.width;
    img->height = info_header.height;
    img->channels = 3;

    int row_size = ((img->width * 3 + 3) / 4) * 4;
    int data_size = row_size * img->height;

    img->data = (uint8_t *)malloc(data_size);
    if (!img->data)
    {
        printf("Ошибка выделения памяти\n");
        fclose(file);
        return 0;
    }

    fseek(file, header.data_offset, SEEK_SET);

    if (fread(img->data, data_size, 1, file) != 1)
    {
        printf("Ошибка чтения данных изображения\n");
        free(img->data);
        fclose(file);
        return 0;
    }

    fclose(file);
    return 1;
}

int save_bmp(const char *filename, const Image *img)
{
    FILE *file = fopen(filename, "wb");
    if (!file)
    {
        printf("Ошибка: не удалось создать файл %s\n", filename);
        return 0;
    }

    int row_size = ((img->width * 3 + 3) / 4) * 4;
    int data_size = row_size * img->height;
    int file_size = 54 + data_size;

    BMPHeader header = {
        .signature = 0x4D42,
        .file_size = file_size,
        .reserved1 = 0,
        .reserved2 = 0,
        .data_offset = 54};

    BMPInfoHeader info_header = {
        .header_size = 40,
        .width = img->width,
        .height = img->height,
        .planes = 1,
        .bits_per_pixel = 24,
        .compression = 0,
        .image_size = data_size,
        .x_pixels_per_meter = 2835,
        .y_pixels_per_meter = 2835,
        .colors_used = 0,
        .colors_important = 0};

    if (fwrite(&header, sizeof(BMPHeader), 1, file) != 1 ||
        fwrite(&info_header, sizeof(BMPInfoHeader), 1, file) != 1 ||
        fwrite(img->data, data_size, 1, file) != 1)
    {
        printf("Ошибка записи в файл\n");
        fclose(file);
        return 0;
    }

    fclose(file);
    return 1;
}

void free_image(Image *img)
{
    if (img && img->data)
    {
        free(img->data);
        img->data = NULL;
    }
}

double get_time_diff(struct timespec start, struct timespec end)
{
    return (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
}
