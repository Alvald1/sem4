bits    64
	
section .data
	
size   db 4
matrix db 5, 6, 7, 1, 15, 13, 14, 10, 16, 2, 3, 11, 12, 4, 8, 9

; 5		6	7	1
; 15	13 	14 	10
; 16 	2 	3 	11
; 12 	4 	8 	9

; 9		9	9	2
; 20	17 	17 	12
; 22 	7 	7 	14
; 19 	10 	13 	13
	
section .text
global  _start
	
_start: 
	movsx r12, byte[size] ; size
	dec   r12

	mov rsi, [matrix] ; указатель на первый элемент

; r13 - кол-во диагоналей
	mov r13, r12
	shl r13, 1   ; r13 * 2	
	inc r13      ; r13 + 1

; (matrix * i) + j

	mov rcx, r13
	
	mov r14, 0   ; начальный i
	mov r15, r12 ; начальный j

	mov r10, 0 ; для тестов

loop_1: ; итерация по кол-ву диагоналей
	push rcx ; созраняем счетчик
	
	mov r8, r14
	mov r9, r15

	inc r10

	call line_traversal

	; пересчет начальный индексов
	test r15, r15 ; если j != 0: j - 1
	jz   L1
	dec  r15
	jmp  L2
L1:
	inc r14 ; если j = 0 : i + 1
L2:


	pop  rcx    ; выгружаем счетчик
	loop loop_1


	mov eax, 60
	mov edi, 0
	syscall

line_traversal:
L4:
	mov  rdx, r12 ; размер
	inc  rdx      ; привести к настоящему размеру
	imul rdx, r8  ; сдвиг на строку
	add  rdx, r9  ; сдвиг на столбец

	add matrix[rdx], r10

	cmp r8, r12 ; i <=> size - 1
	je  L3

	cmp r9, r12 ; j <=> size - 1
	je  L3
	
	inc r8 ; i++
	inc r9 ; j++

	jmp L4

L3:
	ret

