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

# Компиляция общих функций
common.o: common.c common.h
	$(CC) -O2 -c common.c -o common.o

# Компиляция C-реализаций с разными уровнями оптимизации
gaussian-c-O0: gaussian_c.c $(COMMON_OBJS)
	$(CC) -O0 $(CFLAGS_BASE) gaussian_c.c $(COMMON_OBJS) -o gaussian-c-O0

gaussian-c-O1: gaussian_c.c $(COMMON_OBJS)
	$(CC) -O1 $(CFLAGS_BASE) gaussian_c.c $(COMMON_OBJS) -o gaussian-c-O1

gaussian-c-O2: gaussian_c.c $(COMMON_OBJS)
	$(CC) -O2 $(CFLAGS_BASE) gaussian_c.c $(COMMON_OBJS) -o gaussian-c-O2

gaussian-c-O3: gaussian_c.c $(COMMON_OBJS)
	$(CC) -O3 $(CFLAGS_BASE) gaussian_c.c $(COMMON_OBJS) -o gaussian-c-O3

gaussian-c-Ofast: gaussian_c.c $(COMMON_OBJS)
	$(CC) -Ofast $(CFLAGS_BASE) gaussian_c.c $(COMMON_OBJS) -o gaussian-c-Ofast

# Компиляция ASM-реализации (без оптимизаций)
gaussian_blur.o: gaussian_blur.asm
	$(NASM) $(NASMFLAGS) gaussian_blur.asm -o gaussian_blur.o

gaussian-asm: gaussian_asm.c $(COMMON_OBJS) gaussian_blur.o
	$(CC) -O0 $(CFLAGS_BASE) gaussian_asm.c $(COMMON_OBJS) gaussian_blur.o -o gaussian-asm

# Компиляция всех C-версий
all-c: gaussian-c-O0 gaussian-c-O1 gaussian-c-O2 gaussian-c-O3 gaussian-c-Ofast

# Быстрые тесты
test-c: gaussian-c-O2
	./gaussian-c-O2 test_small.bmp output_c_test.bmp

test-asm: gaussian-asm  
	./gaussian-asm test_small.bmp output_asm.bmp

test-all: all-c gaussian-asm
	@echo "Тестирование всех версий..."
	@for opt in O0 O1 O2 O3 Ofast; do \
		echo "Тестирование C-$$opt..."; \
		./gaussian-c-$$opt test_small.bmp output_c_$$opt.bmp; \
	done
	@echo "Тестирование ASM..."
	./gaussian-asm test_small.bmp output_asm.bmp

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

.PHONY: all all-c test-c test-asm test-all report clean clean-all