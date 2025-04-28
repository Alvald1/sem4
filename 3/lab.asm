bits    64

section .data
    buf_size equ 10
    buffer times buf_size db 0
    env_src db 'SRC=',0
    env_dst db 'DST=',0
    tmp     db 0

section .bss
    src_fd  resq 1
    dst_fd  resq 1
    src_ptr resq 1
    dst_ptr resq 1

section .text
    global _start

_start:
    ; Получить адрес envp (x86-64: стек, указатели по 8 байт)
    mov rax, [rsp]   ; argc
    lea rsi, [rsp+8] ; rsi = argv[0]
    mov rcx, rax
    shl rcx, 3       ; rcx = argc * 8 (размер argv[i])
    add rsi, rcx     ; rsi = &argv[argc]
    add rsi, 8       ; пропустить NULL после argv (8 байт)
    mov rbx, rsi     ; rbx = envp[0]
    mov r12, rsi     ; r12 = envp[0], для поиска DST

    ; Найти SRC=
find_src_env:
    mov  rdx, [rbx]     ; rdx = указатель на строку envp[i]
    test rdx, rdx
    jz   src_from_stdin ; если NULL — конец envp, не нашли SRC
    mov  rsi, rdx       ; rsi = строка envp[i]
    mov  rdi, env_src   ; rdi = "SRC="
    mov  rcx, 4
    repe cmpsb
    je   found_src
    add  rbx, 8         ; перейти к следующей строке envp (8 байт)
    jmp  find_src_env
found_src:
    mov rax,       [rbx]     ; rax = указатель на строку "SRC=..."
    lea rax,       [rax+4]   ; rax = указатель на значение после "SRC="
    mov [src_ptr], rax
    ; Открыть исходный файл (SRC)
    mov rax,       2         ; sys_open
    mov rdi,       [src_ptr]
    mov rsi,       0         ; O_RDONLY
    mov rdx,       0         ; mode (не используется)
    syscall
    cmp rax,       0
    js  _exit
    mov [src_fd],  rax
    jmp after_src_open

src_from_stdin:
    mov qword [src_fd], 0 ; stdin

after_src_open:
    ; Найти DST=
    mov rbx, r12 ; rbx = envp[0]
find_dst_env:
    mov  rdx, [rbx]   ; rdx = указатель на строку envp[i]
    test rdx, rdx
    jz   _exit
    mov  rsi, rdx     ; rsi = строка envp[i]
    mov  rdi, env_dst ; rdi = "DST="
    mov  rcx, 4
    repe cmpsb
    je   found_dst
    add  rbx, 8
    jmp  find_dst_env
found_dst:
    mov rax,       [rbx]   ; rax = указатель на строку "DST=..."
    lea rax,       [rax+4] ; rax = указатель на значение после "DST="
    mov [dst_ptr], rax

    ; Открыть/создать целевой файл (DST)
    mov rax,      2         ; sys_open
    mov rdi,      [dst_ptr]
    mov rsi,      577       ; O_WRONLY|O_CREAT|O_TRUNC
    mov rdx,      0o644     ; права доступа rw-r--r--
    syscall
    cmp rax,      0
    js  close_src
    mov [dst_fd], rax

    xor r15, r15


    mov r9, 0 ; Previous char (0 - non-space, 1 - space)
copy_loop:
    ; Читать из src_fd в buffer
    mov rax, 0        ; sys_read
    mov rdi, [src_fd]
    mov rsi, buffer
    mov rdx, buf_size
    syscall
    cmp rax, 0
    jle close_all
    mov r8,  rax      ; r8 = прочитано байт

    ; Удалить лишние разделители в buffer
    mov  rbx, buffer ; rbx = адрес буфера
    mov  rdx, r8     ; rdx = длина прочитанного
    call trim_spaces ; на выходе: rdx = новая длина

    

    ; === Новый цикл: обработка слов ===
    mov rsi, buffer ; rsi = начало буфера (источник)
    mov rcx, rdx    ; rcx = длина буфера
    xor rbx, rbx    ; rbx = текущий индекс в буфере

.process_words:
    cmp rbx, rcx
    jge .end_words

    xor r14, r14

    test rbx,       rbx
    jnz  .next
    cmp  byte[rsi], ' '
    je   .next1
    
    cmp byte[rsi], 10
    jne .next
    
.next1:
    mov r14, 1

    test r15, r15
    je   .next

    push rsi
    push rcx

    mov byte[tmp], ' '
    mov rax,       1
    mov rdi,       [dst_fd]
    mov rsi,       tmp
    mov rdx,       1
    syscall

     ; Записать длину слова (print_int_to_buf)
    mov  edi, r15d        ; число в edi
    call print_int_to_buf
    ; r11 = длина числа, rsi = указатель на строку числа
    mov  rax, 1           ; sys_write
    mov  rdi, [dst_fd]
    mov  rdx, r11         ; длина числа
    syscall

    test r14, r14
    jnz  .m2

    mov byte[tmp], ' '
    mov rax,       1
    mov rdi,       [dst_fd]
    mov rsi,       tmp
    mov rdx,       1
    syscall
.m2:
    pop rcx
    pop rsi

    xor r15, r15


.next:
    ; Пропустить не-слова (разделители)
.skip_nonword:
    cmp rbx, rcx
    jge .end_words
    mov al,  [rsi + rbx]
    cmp al,  ' '
    je  .inc_bx
    cmp al,  10
    je  .inc_nl
    jmp .word_start_found

.inc_nl:
    push rsi
    mov  byte[tmp], 10
    mov  rax,       1
    mov  rdi,       [dst_fd]
    mov  rsi,       tmp
    mov  rdx,       1
    push rcx
    syscall
    pop  rcx
    pop  rsi

.inc_bx:
    inc rbx
    jmp .skip_nonword

.word_start_found:
    mov r8, rbx ; r8 = начало слова

    ; Найти конец слова
.find_word_end:
    cmp rbx, rcx
    jge .copy_word_end
    mov al,  [rsi + rbx]
    cmp al,  ' '
    je  .copy_word
    cmp al,  10
    je  .copy_word
    inc rbx
    jmp .find_word_end

.copy_word_end:
    mov r10, rbx ; r10 = конец слова (не включая)
    sub r10, r8  ; r10 = длина слова


    push rsi
    
    mov  rax, 1             ; sys_write
    mov  rdi, [dst_fd]
    lea  rsi, [buffer + r8]
    mov  rdx, r10           ; длина слова
    push rcx
    syscall
    pop  rcx
    pop  rsi
    add  r15, r10
    jmp  .end_words
    



.copy_word:
    mov r10, rbx ; r10 = конец слова (не включая)
    sub r10, r8  ; r10 = длина слова


    push rsi
    push rcx
    
    mov rax, 1             ; sys_write
    mov rdi, [dst_fd]
    lea rsi, [buffer + r8]
    mov rdx, r10           ; длина слова
   
    syscall


    ; Записать пробел после числа
    mov byte[tmp], ' '
    mov rax,       1
    mov rdi,       [dst_fd]
    mov rsi,       tmp
    mov rdx,       1
    syscall

    add  r10, r15
    ; Записать длину слова (print_int_to_buf)
    mov  edi, r10d        ; число в edi
    call print_int_to_buf
    ; r11 = длина числа, rsi = указатель на строку числа
    mov  rax, 1           ; sys_write
    mov  rdi, [dst_fd]
    mov  rdx, r11         ; длина числа
    syscall

    
    pop rcx
    pop rsi

    cmp byte[rsi + rbx], 10
    je  .m3

    push rsi
    push rcx

    ; Записать пробел после числа
    mov byte[tmp], ' '
    mov rax,       1
    mov rdi,       [dst_fd]
    mov rsi,       tmp
    mov rdx,       1
    syscall
    
    pop rcx
    pop rsi

 .m3:   
    
    xor r15, r15

    jmp .process_words

.end_words:
    ; После обработки слов переходим к следующей порции данных
    jmp copy_loop

close_all:
    ; Закрыть dst_fd
    mov rax, 3        ; sys_close
    mov rdi, [dst_fd]
    syscall

close_src:
    ; Закрыть src_fd
    mov rax, 3        ; sys_close
    mov rdi, [src_fd]
    syscall

_exit:
    mov rax, 60  ; sys_exit
    xor rdi, rdi
    syscall

trim_spaces:
    push rbx
    push rsi
    push rdi
    push rcx
    push rax

    mov rsi, rbx ; Source pointer
    mov rdi, rbx ; Destination pointer
    xor rcx, rcx ; Source index
    xor rax, rax ; Current char
    

    ; Main processing loop
.loop:
    cmp rcx, rdx
    jge .end_loop
    mov al,  [rsi + rcx]

    ; Check for newline character
    cmp al, 10          ; '\n'
    je  .handle_newline

    cmp al, ' '
    je  .not_space2

    cmp al, 9
    jne .not_space
    mov al, ' '
.not_space2:
    ; Handle space character
    cmp r9,    1
    je  .skip_copy
    mov r9,    1
    mov [rdi], al
    inc rdi
    jmp .next

.handle_newline:
    ; Copy newline and skip leading spaces after it
    mov [rdi], al
    inc rdi
    mov r9,    0  ; Reset previous space flag

.skip_after_newline:
    inc rcx
    cmp rcx, rdx
    jge .end_loop           ; End of buffer
    mov al,  [rsi + rcx]
    cmp al,  ' '
    je  .skip_after_newline
    cmp al,  9
    je  .skip_after_newline
    dec rcx                 ; Re-process the non-space character
    jmp .next

.not_space:
    mov r9,    0
    mov [rdi], al
    inc rdi

.skip_copy:
.next:
    inc rcx
    jmp .loop

.end_loop:

    ; Trim trailing spaces
    cmp rdi,        rbx
    je  .no_trailing
    dec rdi
    cmp byte [rdi], ' '
    je  .trim_trailing_loop
    cmp byte [rdi], 9
    jne .no_trailing_inc

.trim_trailing_loop:
    cmp rdi,        rbx
    jl  .trim_done
    cmp byte [rdi], ' '
    je  .m1
    cmp byte [rdi], 9
    jne .trim_done
.m1:
    dec rdi
    jmp .trim_trailing_loop

.trim_done:
    inc rdi

.no_trailing_inc:
    inc rdi

.no_trailing:
    mov rdx, rdi
    sub rdx, rbx ; New length

    pop rax
    pop rcx
    pop rdi
    pop rsi
    pop rbx
    ret


; edi = число
; возвращает: r11 = длина строки, rsi = число 
print_int_to_buf:
    push rax
    push rcx
    push rdx
    push rdi

    mov eax, edi ; число в eax

    mov ecx, 10  ; делитель
    mov rsi, rsp

.print_digit:
    xor edx, edx
    div ecx      ; rdx = остаток

    add edx,   '0'
    dec rsi
    mov [rsi], dl
    
    test eax, eax
    jnz  .print_digit

    lea eax, [rsp]
    sub eax, esi   ; длина числа
    
    mov r11, rax

    pop rdi
    pop rdx
    pop rcx
    pop rax
    ret
