bits    64
	
section .data
%ifndef SORT_ORDER
    SORT_ORDER equ 0 ; Default to ascending order (0), use 1 for descending
%endif
	
sort_order db SORT_ORDER
size       dd 4
matrix     dd 5, 6, 7, 1,  \
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
	mov r12d, [size] ; size
	dec r12d

	lea ebx, [matrix] ; указатель на первый элемент

; r13d - кол-во диагоналей
	mov r13d, r12d
	shl r13d, 1    ; r13d * 2	
	inc r13d       ; r13d + 1

; (matrix * i) + j

	mov ecx, r13d
	
	mov r14d, 0    ; начальный i
	mov r15d, r12d ; начальный j


loop_1: ; итерация по кол-ву диагоналей
	push rcx         ; сохраняем счетчик	
	call insert_sort ; r8d, r9d, r10d, r11d, ecx, edx, ebp - используются
	pop  rcx         ; выгружаем счетчик

	; пересчет начальный индексов
	test r15d, r15d ; если j != 0: j - 1
	jz   L1
	dec  r15d
	jmp  L2
L1:
	inc r14d ; если j = 0 : i + 1
L2:

	loop loop_1


	mov eax, 60
	mov edi, 0
	syscall


calculate_address: ; r8d, r9d, edx
	; r12d - (size - 1)
	; r14d - i база
	; r15d - j база
	; ebx - база
	; edi - индекс
	
	mov r8d, r14d
	add r8d, edi  ; i + индекс

	mov r9d, r15d
	add r9d, edi  ; j + индекс

	cmp r8d, r12d
	jng L5        ; i + индекс <= (size - 1) 	

	mov eax, 0
	ret

L5:
	cmp r9d, r12d
	jng L6        ; j + индекс <= (size - 1)

	mov eax, 0
	ret

L6: 

	mov eax, r8d

	mov edx, r12d
	inc edx       ; size

	imul eax, edx ; i * size
	add  eax, r9d ; (i * size) + j

	lea eax, [ebx + eax * 4] ; (i * size) + j + база 

	ret


bin_search: ; ecx, r8d, r9d, 
	; r12d - (size - 1)
	; r14d - i база
	; r15d - j база
	; ebx - база

	; edi - item
	; r8d - low
	; r9d - high
loop_2:
	cmp r8d, r9d
	jge L7       ; low >= high

	mov ecx, r9d ; high
	sub ecx, r8d ; high - low
	sar ecx, 1   ; (high - low) / 2
	add ecx, r8d ; low + (high - low) / 2 == mid

	push rdi
	push r8
	push r9
	mov  edi, ecx          ; mid
	push rdx
	call calculate_address
	pop  rdx
	pop  r9
	pop  r8
	pop  rdi

	test eax, eax
	jz   buffer_overflow ; eax == 0


	cmp [eax], edi
	jne L8         ; arr[mid] != item
	inc ecx        ; mid + 1
	mov eax,   ecx
	ret

L8:
	cmp byte [sort_order], 0
	jne descending_order_1

	cmp [eax], edi
	; Ascending order logic
	jg  L9         ; arr[mid] > item
	inc ecx        ; mid + 1
	mov r8d,   ecx ; low = mid + 1
	jmp loop_2

descending_order_1:

	cmp [eax], edi
	; Descending order logic
	jl  L9         ; arr[mid] < item (for descending order)
	inc ecx        ; mid + 1
	mov r8d,   ecx ; low = mid + 1
	jmp loop_2

L9:
	dec ecx      ; mid - 1
	mov r9d, ecx ; high = mid - 1
	jmp loop_2

L7:
	push rdi
	push r8
	push r9
	mov  edi, r8d          ; low
	push rdx
	call calculate_address
	pop  rdx
	pop  r9
	pop  r8
	pop  rdi

	test eax, eax
	jz   buffer_overflow ; eax == 0

	cmp byte [sort_order], 0
	jne descending_order_2
	
	; Ascending order logic
	cmp edi, [eax]
	mov eax, r8d   ; low
	jng L10        ; item <= arr[low]	
	inc eax        ; low + 1
	ret

descending_order_2:
	; Descending order logic
	cmp edi, [eax]
	mov eax, r8d   ; low
	jnl L10        ; item >= arr[low] (for descending order)
	inc eax        ; low + 1
	ret

L10:
	ret

calc_diag_len: 
	; r12d - (size - 1)
	; r14d - i база
	; r15d - j база
	
	mov eax,  r12d
	cmp r14d, r15d
	jg  L11        ; i > j
	sub eax,  r15d
	jmp L12

L11:
	sub eax, r14d
L12:
	inc eax
	ret


insert_sort: ; r8d, r9d, r10d, r11d, ecx, edx, ebp
	; r12d - (size - 1)
	; r14d - i база
	; r15d - j база
	; ebx - база

	call calc_diag_len
	mov  r10d, eax     ; diag len
	mov  r8d,  1       ; i

loop_3:
	cmp r8d, r10d
	je  L13

	mov r9d, r8d ; j = i
	dec r9d      ; j--

	mov  edi, r8d          ; i
	push r8
	push r9
	push rdx
	call calculate_address
	pop  rdx
	pop  r9
	pop  r8

	mov r11d, [eax] ; arr[i] == selected

	push r8
	push r9
	push rcx
	mov  edi, r11d
	mov  r8d, 0
	call bin_search ; low = 0, high = j
	pop  rcx
	pop  r9
	pop  r8

	mov edx, eax ; location

loop_4:
	cmp r9d, edx
	jl  L14      ; j < location
	
	push r8
	push r9
	mov  edi, r9d          ; j
	inc  edi               ; j + 1
	push rdx
	call calculate_address
	pop  rdx
	pop  r9
	pop  r8
	
	mov ecx, eax ; arr[j + 1]

	push r8
	push r9
	mov  edi, r9d          ; j
	push rdx
	call calculate_address
	pop  rdx
	pop  r9
	pop  r8

	mov ebp,   [eax] ; arr[j]
	mov [ecx], ebp   ; arr[j + 1] = arr[j]

	dec r9d ; j--

	jmp loop_4

L14:

	push r8
	push r9
	mov  edi, r9d          ; j
	inc  edi               ; j + 1
	push rdx
	call calculate_address
	pop  rdx
	pop  r9
	pop  r8

	mov [eax], r11d

	inc r8d
	jmp loop_3
L13:
	ret



buffer_overflow:
	mov eax, 60
	mov edi, 1
	syscall