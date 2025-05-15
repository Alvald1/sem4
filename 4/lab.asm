bits    64

; arshx = sum(((-1)^n*(2n)!*x^(2n+1))/(4^n*(n!)^2*(2n+1)))
; Вычисление арксинуса гиперболического через ряд Тейлора (double)

section .data
    input_msg           db "Input x (|x| < 1): ", 0
    double_format       db "%lf", 0
    err_inp_msg         db "Error: invalid input!", 10, 0
    out_row_precise_fmt db "series my_arsh(x):%.*f", 10, 0
    out_lib_precise_fmt db "lib asinh(x):     %.*f", 10, 0
    debug_precise_msg   db "n=%d, ratio=%.*f, a_n=%.*f, sum=%.*f", 10, 0
    flt_one             dq 1.0
    flt_minus_one       dq -1.0
    float_abs_mask      dq 0x7fffffffffffffff
    output_file         dq 0
    write_mode          db "w", 0
    file_handle         dq 0
    argc                dq 0
    argv                dq 0
    eps_prompt          db "Input epsilon (e.g. 1e-6): ", 0
    user_epsilon        dq 0.0
    err_file_msg        db "Error: output filename required as argument", 10, 0
    err_open_msg        db "Error: cannot open output file", 10, 0
    err_write_msg       db "Error: failed to write to file", 10, 0

section .text
    global main
    extern printf, scanf, asinh, fopen, fprintf, fclose, log10, floor
    extern getchar

main:
    push rbp
    mov  rbp, rsp
    sub  rsp, 128

    mov [argc], rdi
    mov [argv], rsi

    cmp qword [argc], 2
    jge arg_filename_ok

    mov  rdi, err_file_msg
    xor  eax, eax
    call printf
    mov  eax, 1
    leave
    ret

arg_filename_ok:
    mov rax,           [argv]
    mov rdi,           [rax + 8]
    mov [output_file], rdi

prompt_epsilon:
    mov  rdi, eps_prompt
    xor  eax, eax
    call printf

    mov  rdi, double_format
    lea  rsi, [user_epsilon]
    xor  eax, eax
    call scanf

    cmp eax, 1
    jne .input_invalid_epsilon

    ; --- вычисление количества знаков после запятой ---
    movsd    xmm0, qword [user_epsilon]
    call     log10
    xorpd    xmm1, xmm1
    subsd    xmm1, xmm0
    movapd   xmm0, xmm1
    call     floor
    cvtsd2si r15d, xmm0
    cmp      r15d, 0
    jge      .r15d_ok
    mov      r15d, 0
.r15d_ok:
    jmp open_output_file

.input_invalid_epsilon:
.clear_stdin_buffer:
    call getchar
    cmp  al, 10
    jne  .clear_stdin_buffer
    jmp  prompt_epsilon

open_output_file:
    mov  rdi,           [output_file]
    mov  rsi,           write_mode
    call fopen
    mov  [file_handle], rax

    test rax, rax
    jnz  prompt_input_x

    mov  rdi, err_open_msg
    xor  eax, eax
    call printf
    mov  eax, 1
    leave
    ret

prompt_input_x:
    mov  rdi, input_msg
    xor  eax, eax
    call printf

    mov  rdi, double_format
    lea  rsi, [rbp - 8]
    xor  eax, eax
    call scanf

    cmp eax, 1
    jne .input_invalid

    ; Проверка |x| < 1
    movsd  xmm0, [rbp - 8]
    movsd  xmm1, xmm0
    mov    rax,  [float_abs_mask]
    movq   xmm2, rax
    andpd  xmm1, xmm2
    movsd  xmm3, [flt_one]
    comisd xmm1, xmm3
    jb     calc_lib_arsh

    mov  rdi, err_inp_msg
    xor  eax, eax
    call printf

.input_invalid:
.clear_stdin_buffer_x:
    call getchar
    cmp  al, 10
    jne  .clear_stdin_buffer_x
    jmp  prompt_input_x

calc_lib_arsh:
    movsd xmm0, [rbp - 8]
    call  asinh

    movsd [rbp-16], xmm0
    mov   rdi,      out_lib_precise_fmt
    mov   esi,      r15d
    movsd xmm1,     [rbp-16]
    mov   eax,      2
    call  printf

    movsd xmm0, [rbp - 8]
    call  my_arsh

    movsd [rbp-24], xmm0
    mov   rdi,      out_row_precise_fmt
    mov   esi,      r15d
    movsd xmm1,     [rbp-24]
    mov   eax,      2
    call  printf

    xor eax, eax
    leave
    ret

my_arsh:
    push rbp
    mov  rbp, rsp
    sub  rsp, 64

    movsd xmm1, xmm0 ; x
    movsd xmm2, xmm0 ; term = x
    movsd xmm3, xmm0 ; sum = x

    xor rbx, rbx ; n = 0

series_next_term:
    ; term_{n+1} = term_n * (-1) * (2n+1)^2 * x^2 / [2*(n+1)*(2n+3)]
    mov rax, rbx
    add rax, rax ; 2n
    mov rcx, rax ; rcx = 2n
    add rax, 1   ; 2n+1
    mov rdx, rax ; rdx = 2n+1
    add rcx, 3   ; 2n+3

    cvtsi2sd xmm5, rdx ; xmm5 = 2n+1

    mov      rdx,  rbx
    inc      rdx
    cvtsi2sd xmm7, rdx ; xmm7 = n+1
    cvtsi2sd xmm8, rcx ; xmm8 = 2n+3

    movsd xmm9, xmm1 ; x
    mulsd xmm9, xmm9 ; x^2

    movsd xmm10, [flt_minus_one]
    mulsd xmm10, xmm5
    mulsd xmm10, xmm5
    mulsd xmm10, xmm9

    movsd xmm11, [flt_one]
    addsd xmm11, xmm11

    mulsd xmm11, xmm7
    mulsd xmm11, xmm8

    divsd xmm10, xmm11

    mulsd xmm2, xmm10 ; term = term * ratio

    ; Проверка точности (|term| <= eps)
    movsd  xmm12, xmm2
    mov    rax,   [float_abs_mask]
    movq   xmm13, rax
    andpd  xmm12, xmm13
    movsd  xmm14, [user_epsilon]
    comisd xmm12, xmm14
    jbe    series_finish

    addsd xmm3, xmm2 ; sum += term

    inc rbx ; n++

    ; Сохраняем для отладки (запись в файл)
    push  rax
    push  rbx
    sub   rsp,        8 * 4
    movsd [rsp],      xmm1
    movsd [rsp + 8],  xmm2
    movsd [rsp + 16], xmm3
    movsd [rsp + 24], xmm10

    movsd xmm0, xmm10 ; ratio
    movsd xmm1, xmm2  ; term
    movsd xmm2, xmm3  ; sum

    mov   rdi,  [file_handle]
    mov   rsi,  debug_precise_msg
    mov   rdx,  rbx
    mov   rcx,  r15
    movsd xmm3, xmm0
    mov   r8d,  r15d
    movsd xmm4, xmm1
    mov   r9d,  r15d
    movsd xmm5, xmm2
    mov   eax,  6
    call  fprintf

    movsd xmm1,  [rsp]
    movsd xmm2,  [rsp + 8]
    movsd xmm3,  [rsp + 16]
    movsd xmm10, [rsp + 24]
    add   rsp,   8 * 4
    pop   rbx
    pop   rax

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
    movsd xmm0, xmm3
    leave
    ret