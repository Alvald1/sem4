#include "common.h"
#include <math.h>

// Ядро свертки Гаусса 3x3 (локальная копия для C-реализации)
static const float gaussian_kernel[3][3] = {
    {0.0625f, 0.125f, 0.0625f},
    {0.125f, 0.25f, 0.125f},
    {0.0625f, 0.125f, 0.0625f}};

void gaussian_blur_c_impl(uint8_t *input_data, uint8_t *output_data, int width, int height)
{
    int row_size = ((width * 3 + 3) / 4) * 4;

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
                        sum += input_data[src_offset] * kernel_val;
                    }
                }

                int dst_offset = y * row_size + x * 3 + c;
                output_data[dst_offset] = (uint8_t)(sum + 0.5f); // Округление
            }
        }
    }
}
