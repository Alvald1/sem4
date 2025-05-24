all: lab.asm lab

asm: 
	nasm -f elf64 -g lab.asm -o lab.o

lab: asm
	gcc -static -z noexecstack lab.o -o lab -lm

gdb: all
	gdb ./lab	

run: all
	./lab out && echo "\n==========\nСодержимое файла:\n" && cat out && echo "=========="


clear: rm -rf lab lab.o