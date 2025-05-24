#include "common.h"

// Внешняя функция из ассемблера
extern void gaussian_blur_asm_impl(uint8_t *input, uint8_t *output, int width, int height);

void gaussian_blur_asm(const Image *input, Image *output)
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

    // Вызываем ассемблерную функцию
    gaussian_blur_asm_impl(input->data, output->data, width, height);
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

    // Измеряем время выполнения ASM-реализации
    clock_gettime(CLOCK_MONOTONIC, &start);
    gaussian_blur_asm(&input, &output);
    clock_gettime(CLOCK_MONOTONIC, &end);

    double asm_time = get_time_diff(start, end);
    printf("Время выполнения ASM-реализации: %.6f секунд\n", asm_time);

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
