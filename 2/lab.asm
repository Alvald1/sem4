bits    64
	
section .data
	
size   db 4
matrix db 5, 6, 7, 1, 1, \
          5, 13, 14, 10, \
		  16, 2, 3, 11,  \
		  12, 4, 8, 9

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

	mov rbx, [matrix] ; указатель на первый элемент

; r13 - кол-во диагоналей
	mov r13, r12
	shl r13, 1   ; r13 * 2	
	inc r13      ; r13 + 1

; (matrix * i) + j

	mov rcx, r13
	
	mov r14, 0   ; начальный i
	mov r15, r12 ; начальный j


loop_1: ; итерация по кол-ву диагоналей
	push rcx ; созраняем счетчик
	
	mov  rdi, 2
	call calculate_address

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


calculate_address:
	; r12 - (size - 1)
	; r14 - i база
	; r15 - j база
	; rbx - база
	; rdi - индекс
	
	mov r8, r14
	add r8, rdi ; i + индекс

	mov r9, r15
	add r9, rdi ; j + индекс

	cmp r8, r12
	jng L5      ; i + индекс <= (size - 1) 	

	mov rax, 0
	ret

L5:
	cmp r9, r12
	jng L6      ; j + индекс <= (size - 1)

	mov rax, 0
	ret

L6: 

	mov rax, r8

	mov rdx, r12
	inc rdx      ; size

	imul rax, rdx ; i * size
	add  rax, r9  ; (i * size) + j

	add rax, rbx ; (i * size) + j + база 

	ret
