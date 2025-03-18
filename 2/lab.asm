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
	imul  r8, 2
	sub   r8, 1
; (matrix * i) + j

	mov rcx, r8

loop_1: ; итерация по кол-ву диагоналей
	mov r8, rcx
	
	test rax, rax ;заглушка

	mov  rcx, r8
	loop loop_1


	mov eax, 60
	mov edi, 0
	syscall
