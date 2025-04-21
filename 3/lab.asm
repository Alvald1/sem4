bits    64

section .data
    buf_size equ 64
    buffer times buf_size db 0
    env_src db 'SRC=',0
    env_dst db 'DST=',0

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

    ; Просто записать в dst_fd из buffer
    mov rax, 1        ; sys_write
    mov rdi, [dst_fd]
    mov rsi, buffer
    mov rdx, r8
    syscall
    cmp rax, 0
    jl  close_all

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
