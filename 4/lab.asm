bits    64

; arshx = sum(((-1)^n*(2n)!*x^(2n+1))/(4^n*(n!)^2*(2n+1)))
; Вычисление арксинуса гиперболического через ряд Тейлора

section .data
    input_msg      db "Input x (|x| < 1): ", 0         ; Сообщение для ввода x
    float_format   db "%f", 0                          ; Формат для scanf/printf
    err_inp_msg    db "Error: invalid input!", 10, 0   ; Сообщение об ошибке ввода
    out_lib_msg    db "lib asinhf(x): %f", 10, 0       ; Сообщение для вывода значения из библиотеки
    out_row_msg    db "series my_arsh(x): %f", 10, 0   ; Сообщение для вывода значения по ряду
    flt_one        dd 1.0                              ; Константа 1.0 (float)
    flt_minus_one  dd -1.0                             ; Константа -1.0 (float)
    float_abs_mask dd 0x7fffffff                       ; Маска для получения модуля float
    debug_msg      db "n=%d, ratio=%f, a_n=%f, sum=%f", 10, 0 ; Отладочное сообщение для файла
    output_file    dq 0                                ; Имя выходного файла
    write_mode     db "w", 0                           ; Режим открытия файла (write)
    file_handle    dq 0                                ; Дескриптор файла
    argc           dq 0                                ; Количество аргументов командной строки
    argv           dq 0                                ; Аргументы командной строки
    eps_prompt     db "Input epsilon (e.g. 1e-6): ", 0 ; Сообщение для ввода эпсилон
    user_epsilon   dd 0.0                              ; Значение эпсилон, введённое пользователем
    err_file_msg   db "Error: output filename required as argument", 10, 0 ; Нет имени файла
    err_open_msg   db "Error: cannot open output file", 10, 0              ; Не удалось открыть файл
    err_write_msg  db "Error: failed to write to file", 10, 0              ; Не удалось записать в файл

section .text
    global main
    extern printf, scanf, asinhf, fopen, fprintf, fclose
    extern getchar ; используется для очистки буфера ввода

main:
    push rbp
    mov  rbp, rsp
    sub  rsp, 64

    mov [argc], rdi
    mov [argv], rsi

    cmp qword [argc], 2
    jge arg_filename_ok      ; Проверяем, что передан аргумент с именем файла

    mov  rdi, err_file_msg   ; Если нет — выводим ошибку
    xor  eax, eax
    call printf
    mov  eax, 1
    leave
    ret

arg_filename_ok:
    mov rax,           [argv]
    mov rdi,           [rax + 8]      ; Получаем имя выходного файла
    mov [output_file], rdi

prompt_epsilon:
    mov  rdi, eps_prompt
    xor  eax, eax
    call printf

    mov  rdi, float_format
    lea  rsi, [user_epsilon]
    xor  eax, eax
    call scanf

    cmp eax, 1
    je  open_output_file      ; Если успешно считали — идём дальше

    ; Очистка буфера после неудачного ввода
.clear_stdin_buffer:
    call getchar
    cmp  al, 10              ; '\n'
    jne  .clear_stdin_buffer

    jmp prompt_epsilon       ; Повторяем ввод

open_output_file:
    mov  rdi,           [output_file]
    mov  rsi,           write_mode
    call fopen
    mov  [file_handle], rax

    test rax, rax
    jnz  prompt_input_x      ; Если файл открыт — продолжаем

    mov  rdi, err_open_msg   ; Ошибка открытия файла
    xor  eax, eax
    call printf
    mov  eax, 1
    leave
    ret

prompt_input_x:
    mov  rdi, input_msg
    xor  eax, eax
    call printf

    mov  rdi, float_format
    lea  rsi, [rbp - 4]
    xor  eax, eax
    call scanf

    cmp eax, 1
    jne .input_invalid       ; Если не число — ошибка

    ; Проверка |x| < 1
    movss  xmm0, [rbp - 4]
    movss  xmm1, xmm0
    mov    eax,  [float_abs_mask]
    movd   xmm2, eax
    andps  xmm1, xmm2
    movss  xmm3, [flt_one]
    comiss xmm1, xmm3
    jb     calc_lib_arsh     ; Если модуль меньше 1 — продолжаем

    ; Если не прошло — вывести ошибку и повторить ввод
    mov  rdi, err_inp_msg
    xor  eax, eax
    call printf

.input_invalid:
    ; Очистка буфера после неудачного ввода
.clear_stdin_buffer:
    call getchar
    cmp  al, 10              ; '\n'
    jne  .clear_stdin_buffer

    jmp prompt_input_x       ; Повторяем ввод

calc_lib_arsh:
    movss xmm0, [rbp - 4]
    call  asinhf             ; Вызываем библиотечную функцию asinhf

    cvtss2sd xmm0, xmm0
    mov      rdi,  out_lib_msg
    mov      eax,  1
    call     printf

    movss xmm0, [rbp - 4]
    call  my_arsh            ; Вызываем свою функцию через ряд

    cvtss2sd xmm0, xmm0
    mov      rdi,  out_row_msg
    mov      eax,  1
    call     printf

    xor eax, eax
    leave
    ret

my_arsh:
    push rbp
    mov  rbp, rsp
    sub  rsp, 32

    movss xmm1, xmm0 ; x
    movss xmm2, xmm0 ; term = x (первый член ряда)
    movss xmm3, xmm0 ; sum = x (сумма ряда)

    xor rbx, rbx ; n = 0

series_next_term:
    ; term_{n+1} = term_n * (-1) * (2n+1)^2 * x^2 / [2*(n+1)*(2n+3)]
    mov rax, rbx
    add rax, rax ; 2n
    mov ecx, eax ; ecx = 2n
    add eax, 1   ; 2n+1
    mov edx, eax ; edx = 2n+1
    add ecx, 3   ; 2n+3

    cvtsi2ss xmm5, edx ; xmm5 = 2n+1

    mov      rdx,  rbx
    inc      rdx
    cvtsi2ss xmm7, rdx ; xmm7 = n+1
    cvtsi2ss xmm8, ecx ; xmm8 = 2n+3

    movss xmm9, xmm1 ; x
    mulss xmm9, xmm9 ; x^2

    movss xmm10, [flt_minus_one] ; -1.0
    mulss xmm10, xmm5            ; -1*(2n+1)
    mulss xmm10, xmm5            ; -1*(2n+1)^2
    mulss xmm10, xmm9            ; -1*(2n+1)^2*x^2

    movss xmm11, [flt_one]
    addss xmm11, xmm11     ; 2.0

    mulss xmm11, xmm7 ; 2*(n+1)
    mulss xmm11, xmm8 ; 2*(н+1)*(2н+3)

    divss xmm10, xmm11 ; num/den

    mulss xmm2, xmm10 ; term = term * ratio

    ; Проверка точности (|term| <= eps) — если да, выходим из цикла
    movss  xmm12, xmm2
    mov    eax,   [float_abs_mask]
    movd   xmm13, eax
    andps  xmm12, xmm13
    comiss xmm12, [user_epsilon]
    jbe    series_finish

    addss xmm3, xmm2 ; sum += term

    inc rbx ; n++

    ; Сохраняем для отладки (запись в файл)
    push   rax
    push   rbx
    sub    rsp,        16 * 4
    movdqu [rsp],      xmm1
    movdqu [rsp + 16], xmm2
    movdqu [rsp + 32], xmm3
    movdqu [rsp + 48], xmm10

    cvtss2sd xmm0, xmm10 ; ratio
    cvtss2sd xmm1, xmm2  ; term
    cvtss2sd xmm2, xmm3  ; sum

    mov  rdi, [file_handle]
    mov  rsi, debug_msg
    mov  rdx, rbx
    mov  eax, 2
    call fprintf

    movdqu xmm1,  [rsp]
    movdqu xmm2,  [rsp + 16]
    movdqu xmm3,  [rsp + 32]
    movdqu xmm10, [rsp + 48]
    add    rsp,   16 * 4
    pop    rbx
    pop    rax

    jmp series_next_term

series_finish:
    mov  rdi, [file_handle]
    call fclose

    test eax, eax
    jz   output_file_closed

    mov  rdi, err_write_msg
    xor  eax, eax
    call printf

output_file_closed:
    movss xmm0, xmm3
    leave
    ret