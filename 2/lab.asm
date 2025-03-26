bits    64
	
section .data
%ifndef SORT_ORDER
    SORT_ORDER equ 0 ; Default to ascending order (0), use 1 for descending
%endif
	
sort_order db SORT_ORDER
size       db 4
matrix     db 5, 6, 7, 1,  \
          5, 13, 14, 10, \
		  16, 2, 3, 11,  \
		  12, 4, 8, 9

; 5		6	7	1
; 5		13 	14 	10
; 16 	2 	3 	11
; 12 	4 	8 	9

; 3		6	7	1
; 2		5 	11 	10
; 4 	5 	9 	14
; 12 	16 	8 	13

; 3, 6, 7, 1, 2, 5,	11,	10, 4, 8, 9, 14, 12, 16, 15, 13

; https://www.geeksforgeeks.org/binary-insertion-sort/

	
section .text
global  _start
	
_start: 
	movsx r12, byte[size] ; size
	dec   r12

	lea rbx, [matrix] ; указатель на первый элемент

; r13 - кол-во диагоналей
	mov r13, r12
	shl r13, 1   ; r13 * 2	
	inc r13      ; r13 + 1

; (matrix * i) + j

	mov rcx, r13
	
	mov r14, 0   ; начальный i
	mov r15, r12 ; начальный j


loop_1: ; итерация по кол-ву диагоналей
	push rcx         ; сохраняем счетчик	
	call insert_sort ; r8, r9, r10, r11, rcx, rdx, rbp - используются
	pop  rcx         ; выгружаем счетчик

	; пересчет начальный индексов
	test r15, r15 ; если j != 0: j - 1
	jz   L1
	dec  r15
	jmp  L2
L1:
	inc r14 ; если j = 0 : i + 1
L2:

	loop loop_1


	mov eax, 60
	mov edi, 0
	syscall


calculate_address: ; r8, r9,
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


bin_search: ; rcx, r8, r9, 
	; r12 - (size - 1)
	; r14 - i база
	; r15 - j база
	; rbx - база

	; rdi - item
	; r8 - low
	; r9 - high
loop_2:
	cmp r8, r9
	jge L7     ; low >= high

	mov rcx, r9 ; high
	sub rcx, r8 ; high - low
	sar rcx, 1  ; (high - low) / 2
	add rcx, r8 ; low + (high - low) / 2 == mid

	push rdi
	push r8
	push r9
	mov  rdi, rcx          ; mid
	call calculate_address
	pop  r9
	pop  r8
	pop  rdi

	test rax, rax
	jz   buffer_overflow ; rax == 0


	cmp [rax], rdi
	jne L8         ; arr[mid] != item
	inc rcx        ; mid + 1
	mov rax,   rcx
	ret

L8:
	cmp byte [sort_order], 0
	jne descending_order_1
	
	; Ascending order logic
	jg  L9      ; arr[mid] > item
	inc rcx     ; mid + 1
	mov r8, rcx ; low = mid + 1
	jmp loop_2

descending_order_1:
	; Descending order logic
	jl  L9      ; arr[mid] < item (for descending order)
	inc rcx     ; mid + 1
	mov r8, rcx ; low = mid + 1
	jmp loop_2

L9:
	dec rcx     ; mid - 1
	mov r9, rcx ; high = mid - 1
	jmp loop_2

L7:
	push rdi
	push r8
	push r9
	mov  rdi, r8           ; low
	call calculate_address
	pop  r9
	pop  r8
	pop  rdi

	test rax, rax
	jz   buffer_overflow ; rax == 0

	cmp byte [sort_order], 0
	jne descending_order_2
	
	; Ascending order logic
	cmp rdi, [rax]
	mov rax, r8    ; low
	jng L10        ; item <= arr[low]	
	inc rax        ; low + 1
	ret

descending_order_2:
	; Descending order logic
	cmp rdi, [rax]
	mov rax, r8    ; low
	jnl L10        ; item >= arr[low] (for descending order)
	inc rax        ; low + 1
	ret

L10:
	ret

calc_diag_len: 
	; r12 - (size - 1)
	; r14 - i база
	; r15 - j база
	
	mov rax, r12
	cmp r14, r15
	jg  L11      ; i > j
	sub rax, r15
	jmp L12

L11:
	sub rax, r14
L12:
	inc rax
	ret


insert_sort: ; r8, r9, r10, r11, rcx, rdx, rbp
	; r12 - (size - 1)
	; r14 - i база
	; r15 - j база
	; rbx - база

	call calc_diag_len
	mov  r10, rax      ; diag len
	mov  r8,  1        ; i

loop_3:
	cmp r8, r10
	je  L13

	mov r9, r8 ; j = i
	dec r9     ; j--

	mov  rdi, r8           ; i
	push r8
	push r9
	call calculate_address
	pop  r9
	pop  r8

	mov r11, [rax] ; arr[i] == selected

	push r8
	push r9
	push rcx
	mov  rdi, r11
	mov  r8,  0
	call bin_search ; low = 0, high = j
	pop  rcx
	pop  r9
	pop  r8

	mov rdx, rax ; location

loop_4:
	cmp r9, rdx
	jl  L14     ; j < location
	
	push r8
	push r9
	mov  rdi, r9           ; j
	inc  rdi               ; j + 1
	call calculate_address
	pop  r9
	pop  r8
	
	mov rcx, rax ; arr[j + 1]

	push r8
	push r9
	mov  rdi, r9           ; j
	call calculate_address
	pop  r9
	pop  r8

	mov rbp,   [rax] ; arr[j]
	mov [rcx], rbp   ; arr[j + 1] = arr[j]

	dec r9 ; j--

	jmp loop_4

L14:

	push r8
	push r9
	mov  rdi, r9           ; j
	inc  rdi               ; j + 1
	call calculate_address
	pop  r9
	pop  r8

	mov [rax], r11

	inc r8
	jmp loop_3
L13:
	ret



buffer_overflow:
	mov eax, 60
	mov edi, 1
	syscall