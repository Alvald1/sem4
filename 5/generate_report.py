#!/usr/bin/env python3
"""
Создает отчет по лабораторной работе №5
"""

import subprocess
import os

# КОНСТАНТЫ РАЗМЕРОВ ИЗОБРАЖЕНИЙ
IMAGE_SIZES = [
    (300, 300, "small"),   # ширина, высота, имя
    (1000, 1000, "medium"),
    (10000, 10000, "large")
]


def create_test_images():
    """Создает тестовые изображения разных размеров"""
    import struct

    # Создаем папку для датасета
    dataset_dir = "dataset"
    if not os.path.exists(dataset_dir):
        os.makedirs(dataset_dir)
        print(f"Создана папка для датасета: {dataset_dir}")

    def create_bmp(filename, width, height):
        file_size = 54 + width * height * 3
        bmp_header = struct.pack('<2sIHHI', b'BM', file_size, 0, 0, 54)
        dib_header = struct.pack('<IiiHHIIiiII', 40, width, height, 1, 24, 0,
                                 width * height * 3, 2835, 2835, 0, 0)

        pixel_data = bytearray()
        for y in range(height):
            row = bytearray()
            for x in range(width):
                # Создаем узор для тестирования
                if (x // 20 + y // 20) % 2 == 0:
                    row.extend([255, 255, 255])  # Белый
                else:
                    row.extend([100, 150, 200])  # Цветной
            # Выравнивание по 4 байта
            while len(row) % 4 != 0:
                row.append(0)
            pixel_data.extend(row)

        with open(filename, 'wb') as f:
            f.write(bmp_header)
            f.write(dib_header)
            # BMP хранится снизу вверх
            for y in range(height - 1, -1, -1):
                row_start = y * ((width * 3 + 3) // 4 * 4)
                row_end = row_start + ((width * 3 + 3) // 4 * 4)
                f.write(pixel_data[row_start:row_end])

    # Создаем изображения разных размеров на основе констант
    created_files = []
    skipped_files = []

    for width, height, name in IMAGE_SIZES:
        filename = os.path.join(dataset_dir, f'test_{name}.bmp')

        # Проверяем, существует ли файл
        if os.path.exists(filename):
            skipped_files.append(filename)
            continue

        create_bmp(filename, width, height)
        created_files.append(filename)

    if created_files:
        print(f"Созданы тестовые изображения: {', '.join(created_files)}")
    if skipped_files:
        print(f"Пропущены существующие файлы: {', '.join(skipped_files)}")
    if not created_files and not skipped_files:
        print("Не удалось создать тестовые изображения")


def run_test(executable, input_file, output_file):
    """Запускает тест и возвращает результаты"""
    try:
        result = subprocess.run([executable, input_file, output_file],
                                capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            output = result.stdout
            # Извлекаем время выполнения
            time_value = None

            for line in output.split('\n'):
                if 'Время выполнения C-реализации:' in line:
                    time_value = float(line.split(': ')[1].split(' ')[0])
                elif 'Время выполнения ASM-реализации:' in line:
                    time_value = float(line.split(': ')[1].split(' ')[0])

            return time_value, True
        else:
            return None, False
    except Exception as e:
        print(f"Ошибка при запуске {executable}: {e}")
        return None, False


def create_result_directories():
    """Создает папки для результатов тестирования"""
    base_dir = "res"
    subdirs = ["o0", "o1", "o2", "o3", "ofast", "asm"]

    # Создаем базовую папку
    if not os.path.exists(base_dir):
        os.makedirs(base_dir)

    # Создаем подпапки
    for subdir in subdirs:
        full_path = os.path.join(base_dir, subdir)
        if not os.path.exists(full_path):
            os.makedirs(full_path)

    print(f"Созданы папки для результатов: {', '.join(subdirs)}")


def main():
    print("=" * 70)
    print("Размытие изображения по Гауссу: C vs ASM")
    print("=" * 70)
    print()

    # Создаем папки для результатов
    print("Создание папок для результатов...")
    create_result_directories()
    print()

    # Создаем тестовые изображения
    print("Создание тестовых изображений...")
    create_test_images()
    print()

    # Списки исполняемых файлов
    c_executables = [
        'gaussian-c-O0',
        'gaussian-c-O1',
        'gaussian-c-O2',
        'gaussian-c-O3',
        'gaussian-c-Ofast']
    asm_executable = 'gaussian-asm'

    # Генерируем список тестовых файлов на основе констант
    test_files = []
    for width, height, name in IMAGE_SIZES:
        test_files.append(
            (os.path.join(
                "dataset",
                f'test_{name}.bmp'),
                f'{width}x{height}'))

    # Маппинг уровней оптимизации на папки
    opt_to_dir = {
        'O0': 'o0', 'O1': 'o1', 'O2': 'o2', 'O3': 'o3', 'Ofast': 'ofast'
    }

    print("РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ C-РЕАЛИЗАЦИИ")
    print("=" * 70)
    print(f"{'Оптимизация':<12} {'Размер':<12} {'Время (с)':<12}")
    print("-" * 40)

    c_results = []

    # Тестируем C-реализации
    for exe in c_executables:
        if not os.path.exists(exe):
            print(f"Исполняемый файл {exe} не найден!")
            continue

        for test_file, size in test_files:
            if not os.path.exists(test_file):
                print(f"Тестовый файл {test_file} не найден!")
                continue

            opt_level = exe.replace('gaussian-c-', '')
            result_dir = os.path.join(
                "res", opt_to_dir.get(
                    opt_level, opt_level.lower()))

            # Создаем имена выходных файлов
            base_name = os.path.splitext(os.path.basename(test_file))[0]
            output_file = os.path.join(
                result_dir, f"{base_name}_c_{opt_level}.bmp")

            time_value, success = run_test(f"./{exe}", test_file, output_file)

            if success and time_value is not None:
                print(f"{opt_level:<12} {size:<12} {time_value:<12.6f}")
                c_results.append((opt_level, size, time_value))
            else:
                print(f"{opt_level:<12} {size:<12} {'ОШИБКА':<12}")

    print("\nРЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ ASM-РЕАЛИЗАЦИИ")
    print("=" * 70)
    print(f"{'Реализация':<12} {'Размер':<12} {'Время (с)':<12}")
    print("-" * 40)

    asm_results = []

    # Тестируем ASM-реализацию
    if os.path.exists(asm_executable):
        for test_file, size in test_files:
            if not os.path.exists(test_file):
                continue

            base_name = os.path.splitext(os.path.basename(test_file))[0]
            output_file = os.path.join("res", "asm", f"{base_name}_asm.bmp")

            time_value, success = run_test(
                f"./{asm_executable}", test_file, output_file)

            if success and time_value is not None:
                print(f"{'ASM':<12} {size:<12} {time_value:<12.6f}")
                asm_results.append(('ASM', size, time_value))
            else:
                print(f"{'ASM':<12} {size:<12} {'ОШИБКА':<12}")
    else:
        print(f"Исполняемый файл {asm_executable} не найден!")

    print("\nАНАЛИЗ РЕЗУЛЬТАТОВ")
    print("=" * 70)

    if c_results and asm_results:
        print(
            f"\n{
                'Размер':<12} {
                'C (O0)':<12} {
                'C (O1)':<12} {
                'C (O2)':<12} {
                    'C (O3)':<12} {
                        'C (Ofast)':<12} {
                            'ASM':<12}")
        print("-" * 100)

        for width, height, name in IMAGE_SIZES:
            size = f'{width}x{height}'

            # Находим результаты для данного размера
            c_o0 = next((r[2] for r in c_results if r[1]
                        == size and r[0] == 'O0'), None)
            c_o1 = next((r[2] for r in c_results if r[1]
                        == size and r[0] == 'O1'), None)
            c_o2 = next((r[2] for r in c_results if r[1]
                        == size and r[0] == 'O2'), None)
            c_o3 = next((r[2] for r in c_results if r[1]
                        == size and r[0] == 'O3'), None)
            c_ofast = next((r[2] for r in c_results if r[1]
                            == size and r[0] == 'Ofast'), None)
            asm_time = next(
                (r[2] for r in asm_results if r[1] == size), None)

            # Выводим времена выполнения
            print(f"{size:<12} ", end="")
            for time_val in [c_o0, c_o1, c_o2, c_o3, c_ofast, asm_time]:
                if time_val is not None:
                    print(f"{time_val:<12.6f} ", end="")
                else:
                    print(f"{'N/A':<12} ", end="")
            print()


if __name__ == '__main__':
    main()
