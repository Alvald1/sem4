#include "common.h"

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Использование: %s <входной_файл.bmp> <выходной_файл.bmp>\n", argv[0]);
        return 1;
    }

    Image input, output;

    // Загружаем входное изображение
    if (!load_bmp(argv[1], &input))
    {
        return 1;
    }

    printf("Загружено изображение: %dx%d пикселей\n", input.width, input.height);

    double execution_time = gaussian_blur(&input, &output);

#ifdef USE_ASM
    printf("Время выполнения ASM-реализации: %.6f секунд\n", execution_time);
#else
    printf("Время выполнения C-реализации: %.6f секунд\n", execution_time);
#endif

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
