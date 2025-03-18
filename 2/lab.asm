bits    64
	
section .data
	
size   db 4
matrix db 5, 6, 7, 1, 15, 13, 14, 10, 16, 2, 3, 11, 12, 4, 8, 9

; 5		6	7	1
; 15	13 	14 	10
; 16 	2 	3 	11
; 12 	4 	8 	9
	
section .text
global  _start
	
_start: 
; r8 - кол-во диагоналей
	movsx r8, byte[size]
	shl   r8, 1          ; r8 * 2	
	dec   r8             ; r8 - 1

; (matrix * i) + j

	mov rcx, r8
	
	mov   r14, 0          ; начальный i
	movsx r15, byte[size] ; начальный j
	dec   r15

loop_1: ; итерация по кол-ву диагоналей
	mov r8, rcx ; созраняем счетчик
	

	; пересчет начальный индексов
	test r15, r15 ; если j != 0: j - 1
	jnz  L1
	dec  r15
L1:
	inc r14 ; если j = 0 : i + 1

	

	mov  rcx, r8 ; выгружаем счетчик
	loop loop_1


	mov eax, 60
	mov edi, 0
	syscall
