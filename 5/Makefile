# Makefile для лабораторной работы №5
# Раздельная компиляция C и ASM реализаций

CC = gcc
NASM = nasm
CFLAGS_BASE = -Wall -static -z noexecstack -lm
NASMFLAGS = -f elf64 -g

# Общие объектные файлы
COMMON_OBJS = common.o

# Цели по умолчанию
all: gaussian-c-O0 gaussian-c-O1 gaussian-c-O2 gaussian-c-O3 gaussian-c-Ofast gaussian-asm

# Компиляция общих функций (всегда с O2)
common.o: common.c common.h
	$(CC) -O2 -c common.c -o common.o

# Компиляция C-реализации алгоритма с разными уровнями оптимизации
gaussian_c_impl_O0.o: gaussian_c.c common.h
	$(CC) -O0 -c gaussian_c.c -o gaussian_c_impl_O0.o

gaussian_c_impl_O1.o: gaussian_c.c common.h
	$(CC) -O1 -c gaussian_c.c -o gaussian_c_impl_O1.o

gaussian_c_impl_O2.o: gaussian_c.c common.h
	$(CC) -O2 -c gaussian_c.c -o gaussian_c_impl_O2.o

gaussian_c_impl_O3.o: gaussian_c.c common.h
	$(CC) -O3 -c gaussian_c.c -o gaussian_c_impl_O3.o

gaussian_c_impl_Ofast.o: gaussian_c.c common.h
	$(CC) -O3 -ffast-math -c gaussian_c.c -o gaussian_c_impl_Ofast.o

# Компиляция ассемблерного кода
gaussian_blur.o: gaussian_blur.asm
	$(NASM) $(NASMFLAGS) gaussian_blur.asm -o gaussian_blur.o

# Компиляция C-реализаций с разными уровнями оптимизации
# main.c всегда компилируется с O2, только gaussian_c.c с указанным уровнем
gaussian-c-O0: main.c $(COMMON_OBJS) gaussian_c_impl_O0.o
	$(CC) $(CFLAGS_BASE) main.c $(COMMON_OBJS) gaussian_c_impl_O0.o -o gaussian-c-O0

gaussian-c-O1: main.c $(COMMON_OBJS) gaussian_c_impl_O1.o
	$(CC) $(CFLAGS_BASE) main.c $(COMMON_OBJS) gaussian_c_impl_O1.o -o gaussian-c-O1

gaussian-c-O2: main.c $(COMMON_OBJS) gaussian_c_impl_O2.o
	$(CC) $(CFLAGS_BASE) main.c $(COMMON_OBJS) gaussian_c_impl_O2.o -o gaussian-c-O2

gaussian-c-O3: main.c $(COMMON_OBJS) gaussian_c_impl_O3.o
	$(CC) $(CFLAGS_BASE) main.c $(COMMON_OBJS) gaussian_c_impl_O3.o -o gaussian-c-O3

gaussian-c-Ofast: main.c $(COMMON_OBJS) gaussian_c_impl_Ofast.o
	$(CC) $(CFLAGS_BASE) main.c $(COMMON_OBJS) gaussian_c_impl_Ofast.o -o gaussian-c-Ofast

# Компиляция ASM-реализации (с макросом USE_ASM)
# main.c компилируется с O2, используется любая C-реализация для линковки (но не вызывается)
gaussian-asm: main.c $(COMMON_OBJS) gaussian_c_impl_O2.o gaussian_blur.o
	$(CC)  -DUSE_ASM $(CFLAGS_BASE) main.c $(COMMON_OBJS) gaussian_c_impl_O2.o gaussian_blur.o -o gaussian-asm

# Генерация отчета
report: all
	python3 generate_report.py

# Очистка
clean:
	rm -f *.o gaussian-c-* gaussian-asm output*.bmp

# Полная очистка
clean-all: clean
	rm -rf res/
	rm -rf dataset

.PHONY: all report clean clean-all