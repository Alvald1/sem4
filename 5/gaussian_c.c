#include "common.h"

void gaussian_blur_c_impl(uint8_t *input_data, uint8_t *output_data, int width, int height, const int *kernel)
{
    int row_size = ((width * 3 + 3) / 4) * 4;

    // Применяем размытие по Гауссу
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            for (int c = 0; c < 3; c++)
            { // BGR каналы
                int sum = 0;

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
                        int kernel_index = (ky + 1) * 3 + (kx + 1);
                        int kernel_val = kernel[kernel_index];
                        sum += input_data[src_offset] * kernel_val;
                    }
                }

                // Нормализуем результат (делим на 1024 и округляем)
                sum += 512; // добавляем 0.5 * 1024 для округления
                sum >>= 10; // делим на 1024

                // Ограничиваем значение диапазоном [0, 255]
                if (sum > 255)
                    sum = 255;

                int dst_offset = y * row_size + x * 3 + c;
                output_data[dst_offset] = (uint8_t)sum;
            }
        }
    }
}
