#include "common.h"
#include <math.h>

// Ядро свертки Гаусса 3x3
static const float gaussian_kernel[3][3] = {
    {0.0625f, 0.125f, 0.0625f},
    {0.125f, 0.25f, 0.125f},
    {0.0625f, 0.125f, 0.0625f}};

void gaussian_blur_c(const Image *input, Image *output)
{
    int width = input->width;
    int height = input->height;
    int row_size = ((width * 3 + 3) / 4) * 4;

    // Инициализируем выходное изображение
    output->width = width;
    output->height = height;
    output->channels = 3;
    output->data = (uint8_t *)malloc(row_size * height);

    if (!output->data)
    {
        printf("Ошибка выделения памяти для выходного изображения\n");
        return;
    }

    // Применяем размытие по Гауссу
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            for (int c = 0; c < 3; c++)
            { // BGR каналы
                float sum = 0.0f;

                // Применяем ядро свертки 3x3
                for (int ky = -1; ky <= 1; ky++)
                {
                    for (int kx = -1; kx <= 1; kx++)
                    {
                        int px = x + kx;
                        int py = y + ky;

                        // Обработка границ (зеркальное отражение)
                        if (px < 0)
                            px = -px;
                        if (px >= width)
                            px = 2 * width - px - 1;
                        if (py < 0)
                            py = -py;
                        if (py >= height)
                            py = 2 * height - py - 1;

                        int src_offset = py * row_size + px * 3 + c;
                        float kernel_val = gaussian_kernel[ky + 1][kx + 1];
                        sum += input->data[src_offset] * kernel_val;
                    }
                }

                int dst_offset = y * row_size + x * 3 + c;
                output->data[dst_offset] = (uint8_t)(sum + 0.5f); // Округление
            }
        }
    }
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Использование: %s <входной_файл.bmp> <выходной_файл.bmp>\n", argv[0]);
        return 1;
    }

    Image input, output;
    struct timespec start, end;

    // Загружаем входное изображение
    if (!load_bmp(argv[1], &input))
    {
        return 1;
    }

    printf("Загружено изображение: %dx%d пикселей\n", input.width, input.height);

    // Измеряем время выполнения C-реализации
    clock_gettime(CLOCK_MONOTONIC, &start);
    gaussian_blur_c(&input, &output);
    clock_gettime(CLOCK_MONOTONIC, &end);

    double c_time = get_time_diff(start, end);
    printf("Время выполнения C-реализации: %.6f секунд\n", c_time);

    // Сохраняем результат
    if (!save_bmp(argv[2], &output))
    {
        free_image(&input);
        free_image(&output);
        return 1;
    }

    printf("Результат сохранен в %s\n", argv[2]);

    free_image(&input);
    free_image(&output);
    return 0;
}
