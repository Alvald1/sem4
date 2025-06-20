# Лабораторная работа №4: Вычисление арксинуса гиперболического через ряд Тейлора

## 📋 Описание задачи
**Вариант №6**

Реализация вычисления арксинуса гиперболического `asinh(x)` через разложение в ряд Тейлора с использованием смешанного программирования (C + Assembly) и записью результатов в файл. Дополнительно выполняется сравнение с библиотечной функцией для проверки точности.

## 📐 Математическая формула
```
arsh(x) = ln(x + √(x² + 1)) = x - x³/6 + 3x⁵/40 - ⋯
```

### Ряд Тейлора:
```
asinh(x) = ∑(n=0 to ∞) [(-1)ⁿ * (2n)! * x^(2n+1)] / [4ⁿ * (n!)² * (2n+1)]
```

### Ограничения:
- **Область сходимости**: |x| < 1
- **Точность**: Определяется пользователем (epsilon)
- **Тип данных**: Число с плавающей точкой двойной точности

## 🏗️ Структура проекта
```
├── lab.asm         # Ассемблерная реализация (основная логика)
├── Makefile        # Система сборки
├── bin             # Исполняемый файл
├── lab4.pdf        # Условие задачи
└── obj/
    └── lab.o       # Объектный файл
```

## 🚀 Сборка и запуск

### Компиляция
```bash
make all
```

### Запуск программы
```bash
./bin output.txt
```

### Очистка файлов сборки
```bash
make clean
```

## 📊 Интерактивное взаимодействие

### Входные параметры:
1. **Аргумент командной строки**: Имя выходного файла
2. **Значение x**: Число для вычисления asinh(x), где |x| < 1
3. **Точность epsilon**: Критерий остановки ряда (например, 1e-6)

### Выходные данные:
1. **Значение ряда**: Результат вычисления через разложение в ряд
2. **Библиотечное значение**: Результат функции ln(x + √(x² + 1))
3. **Сравнение точности**: Демонстрация совпадения результатов

### Пример сессии:
```
$ ./bin result.txt
Input x (|x| < 1): 0.5
Input epsilon (e.g. 1e-6): 1e-8
```

## 🔄 Алгоритм вычисления

### Итеративный процесс:
1. **Инициализация**: Первый член ряда a₀ = x
2. **Вычисление отношения**: ratio = [-(2n-1)*(2n)*x²] / [(2n)*(2n+1)]
3. **Обновление члена**: aₙ = aₙ₋₁ * ratio
4. **Накопление суммы**: sum += aₙ
5. **Проверка сходимости**: |aₙ| < epsilon

### Оптимизации:
- **Рекуррентная формула**: Избегание вычисления факториалов
- **Контроль точности**: Динамическое определение количества знаков
- **Проверка сходимости**: Остановка при достижении заданной точности

## ⚙️ Особенности реализации

### Смешанное программирование:
- **C-функции**: printf, scanf, fopen, fprintf, asinh (для сравнения)
- **Assembly**: Основной алгоритм вычисления ряда
- **Интерфейс**: Передача параметров через стек и регистры

### Работа с файлами:
- **Проверка аргументов**: Валидация имени файла
- **Открытие файла**: Режим записи с обработкой ошибок
- **Форматированный вывод**: Запись результатов с заданной точностью
- **Корректное закрытие**: Освобождение ресурсов

### Точность вычислений:
- **Double precision**: 64-битные числа с плавающей точкой
- **Динамическая точность**: Автоматическое определение количества значащих цифр
- **Сравнение с библиотекой**: Использование asinh() для верификации

## 📝 Формат выходного файла

```
series my_arsh(x): 0.48121182506
lib ln(x+√(x²+1)): 0.48121182506
```

### Отладочная информация (опционально):
```
n=0, ratio=0.250000, a_n=0.500000, sum=0.500000
n=1, ratio=-0.041667, a_n=-0.020833, sum=0.479167
n=2, ratio=-0.017857, a_n=0.000372, sum=0.479539
...
```

## 🔍 Тестирование

### Тестовые значения:
```bash
# Простые случаи
./bin test1.txt  # x=0.0 (должно быть 0.0)
./bin test2.txt  # x=0.5 (сравнить с ln(0.5 + √(0.25 + 1)))
./bin test3.txt  # x=0.9 (близко к границе сходимости)
```

### Проверка точности:
- Сравнение с аналитическим выражением `ln(x + √(x² + 1))`
- Тестирование разных значений epsilon
- Анализ скорости сходимости ряда

## 🎯 Учебные цели
- Изучение рядов Тейлора и их программной реализации
- Практика смешанного программирования C+Assembly
- Работа с числами двойной точности в ассемблере
- Контроль точности и сходимости численных методов
- Файловый ввод/вывод в системном программировании

## 🛠️ Системы сборки
- **Ассемблер**: NASM (64-битный ELF)
- **Компилятор C**: GCC (для библиотечных функций)
- **Линковщик**: GCC (автоматическое связывание с libc и libm)
- **Математические функции**: Линковка с libm (-lm)
