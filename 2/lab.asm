bits    64
	
section .data
	
size   db 4
matrix db 5, 6, 7, 1, 15, 13, 14, 10, 16, 2, 3, 11, 12, 4, 8, 9
temp   db 0                                                     ; Temporary storage for swapping

section .text
global  _start

_start:
    ; Get the size of matrix
    movzx r12, byte [size]
    
    ; Process each diagonal perpendicular to the main diagonal (anti-diagonals)
    ; Number of diagonals = 2*size - 1
    mov r13, 0 ; Diagonal counter (0 to 2*size-2)
    
diagonal_loop:
    ; Check if we've processed all diagonals
    mov rax, r12
    add rax, r12
    sub rax, 1
    cmp r13, rax
    jge program_end
    
    ; Calculate diagonal length and starting position
    call calculate_diagonal_info
    ; r14 = diagonal length
    ; r15 = starting position in the matrix
    
    ; If diagonal length ≤ 1, no need to sort
    cmp r14, 1
    jle next_diagonal
    
    ; Sort this diagonal using insertion sort with binary search
    call sort_diagonal
    
next_diagonal:
    ; Move to the next diagonal
    inc r13
    jmp diagonal_loop
    
program_end:
    ; Exit program
    mov eax, 60
    mov edi, 0
    syscall

; Calculate diagonal length and starting position for anti-diagonals
; Input: r12 = matrix size, r13 = diagonal number
; Output: r14 = diagonal length, r15 = starting position
calculate_diagonal_info:
    ; Determine which half of the matrix we're in
    mov rax, r12
    dec rax
    cmp r13, rax
    jg  second_half
    
    ; First half (0 to size-2)
    mov r14, r13 ; Length = diagonal_num + 1
    inc r14
    
    ; Starting position = (size-1, 0) for first anti-diagonal, then move up
    mov  r15, r12
    dec  r15       ; size-1 (last row)
    imul r15, r12  ; Convert to offset
    sub  r15, r13  ; Move up by diagonal number
    jmp  calc_done
    
second_half:
    ; Second half (size-1 to 2*size-2)
    mov r14, r12
    add r14, r12
    dec r14
    sub r14, r13 ; Length = 2*size - 1 - diagonal_num
    
    ; Starting position = (0, diagonal_num-size+1)
    mov r15, r13
    sub r15, r12
    inc r15      ; Column offset = diagonal_num-size+1
    
calc_done:
    ret

; Sort a diagonal using insertion sort with binary search
; Input: r14 = diagonal length, r15 = starting position
sort_diagonal:
    ; Outer loop for insertion sort
    mov rcx, 1 ; Start from the second element
    
outer_loop:
    cmp rcx, r14
    jge sort_done
    
    ; Get current element
    mov   rsi,         rcx                 ; Calculate position of current element
    call  get_diagonal_element_pos
    movzx rbx,         byte [matrix + rax] ; Current element value
    mov   byte [temp], bl                  ; Save current element
    
    ; Binary search to find insertion point
    mov r8, 0   ; Left = 0
    mov r9, rcx ; Right = current position
    dec r9
    
binary_search:
    cmp r8, r9
    jg  binary_done
    
    ; Calculate mid = (left + right) / 2
    mov rax, r8
    add rax, r9
    shr rax, 1
    
    ; Compare array[mid] with key
    mov   rsi, rax
    call  get_diagonal_element_pos
    movzx rdx, byte [matrix + rax] ; array[mid]
    
    cmp dl, byte [temp]
    je  binary_done     ; Found equal element
    jg  move_left
    
    ; array[mid] < key, go right
    inc rax
    mov r8, rax
    jmp binary_search
    
move_left:
    ; array[mid] > key, go left
    dec rax
    mov r9, rax
    jmp binary_search
    
binary_done:
    ; r8 now holds insertion point
    
    ; Shift elements to make room for insertion
    mov rdx, rcx
    dec rdx
    
shift_loop:
    cmp rdx, r8
    jl  shift_done
    
    ; Shift element at position rdx to position rdx+1
    mov  rsi, rdx
    call get_diagonal_element_pos
    mov  rdi, rax                 ; Save source position
    
    mov  rsi, rdx
    inc  rsi
    call get_diagonal_element_pos
    mov  rsi, rax                 ; Save destination position
    
    movzx rdx,                 byte [matrix + rdi]
    mov   byte [matrix + rsi], dl
    
    ; Continue shifting
    mov rdx, rdi
    shr rdx, 2     ; Convert offset to index
    dec rdx
    jmp shift_loop
    
shift_done:
    ; Insert the element at position r8
    mov   rsi,                 r8
    call  get_diagonal_element_pos
    movzx edx,                 byte [temp]
    mov   byte [matrix + rax], dl
    
    ; Next element
    inc rcx
    jmp outer_loop
    
sort_done:
    ret

; Calculate position of anti-diagonal element in the matrix
; Input: r15 = diagonal start, rsi = element index in diagonal
; Output: rax = position in matrix
get_diagonal_element_pos:
    ; For anti-diagonals (perpendicular to the main diagonal):
    ; position = start + index*(size-1)
    mov  rax, r12
    dec  rax      ; size-1
    imul rsi, rax ; index * (size-1)
    add  rsi, r15 ; start + index*(size-1)
    mov  rax, rsi
    ret
