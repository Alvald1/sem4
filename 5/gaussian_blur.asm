section .text
    global gaussian_blur_asm_impl

; Функция: gaussian_blur_asm_impl
; Параметры:
;   rdi - указатель на входные данные (uint8_t *input)
;   rsi - указатель на выходные данные (uint8_t *output) 
;   rdx - ширина изображения (int width)
;   rcx - высота изображения (int height)
;   r8  - указатель на матрицу свертки (const int *kernel)
gaussian_blur_asm_impl:
    push rbp
    mov  rbp, rsp
    
    ; Сохраняем регистры
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Сохраняем параметры
    mov  r12, rdi ; input
    mov  r13, rsi ; output
    mov  r14, rdx ; width
    mov  r15, rcx ; height
    push r8       ; kernel (сохраняем в стеке)
    
    ; Вычисляем row_size = ((width * 3 + 3) / 4) * 4
    mov  rax, r14
    imul rax, 3   ; width * 3
    add  rax, 3   ; + 3
    shr  rax, 2   ; / 4
    shl  rax, 2   ; * 4
    mov  r8,  rax ; row_size в r8
    
    ; Внешний цикл по строкам (y)
    xor r9, r9 ; y = 0
    
.y_loop:
    cmp r9, r15 ; y < height?
    jge .done
    
    ; Внутренний цикл по столбцам (x)
    xor r10, r10 ; x = 0
    
.x_loop:
    cmp r10, r14 ; x < width?
    jge .next_y
    
    ; Цикл по каналам (c = 0, 1, 2 для BGR)
    xor r11, r11 ; c = 0
    
.channel_loop:
    cmp r11, 3  ; c < 3?
    jge .next_x
    
    ; Инициализируем сумму
    xor rax, rax ; sum = 0
    
    ; Применяем ядро свертки 3x3
    ; ky = -1
    mov  rbx, -1           ; ky
    call .apply_kernel_row
    
    ; ky = 0
    mov  rbx, 0            ; ky  
    call .apply_kernel_row
    
    ; ky = 1
    mov  rbx, 1            ; ky
    call .apply_kernel_row
    
    ; Нормализуем результат (делим на 1024 и округляем)
    add rax, 512 ; добавляем 0.5 * 1024 для округления
    shr rax, 10  ; делим на 1024
    
    ; Ограничиваем значение диапазоном [0, 255]
    cmp rax, 255
    jle .clamp_ok
    mov rax, 255
    
.clamp_ok:
    ; Вычисляем смещение в выходных данных: dst_offset = y * row_size + x * 3 + c
    push rdx
    mov  rdx, r9
    imul rdx, r8  ; y * row_size
    push rdi
    mov  rdi, r10
    imul rdi, 3   ; x * 3
    add  rdx, rdi ; y * row_size + x * 3
    add  rdx, r11 ; + c
    
    ; Сохраняем результат
    mov [r13 + rdx], al
    
    pop rdi
    pop rdx
    
    inc r11           ; c++
    jmp .channel_loop
    
.next_x:
    inc r10     ; x++
    jmp .x_loop
    
.next_y:
    inc r9      ; y++
    jmp .y_loop
    
.done:
    ; Восстанавливаем регистры
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    mov rsp, rbp
    pop rbp
    ret

; Подпрограмма для применения одной строки ядра
; rbx = ky (-1, 0, 1)
; Использует и модифицирует rax (сумма)
.apply_kernel_row:
    push rcx
    push rdx
    push rdi
    push rsi
    
    ; kx = -1
    mov  rcx, -1
    call .apply_single_kernel
    
    ; kx = 0  
    mov  rcx, 0
    call .apply_single_kernel
    
    ; kx = 1
    mov  rcx, 1
    call .apply_single_kernel
    
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    ret

; Подпрограмма для применения одного элемента ядра
; rbx = ky, rcx = kx
; Использует и модифицирует rax (сумма)
.apply_single_kernel:
    push rdx
    push rdi
    push rsi
    
    ; Вычисляем px = x + kx
    mov rdx, r10
    add rdx, rcx ; px = x + kx
    
    ; Обработка границ для px (зеркальное отражение)
    cmp rdx, 0
    jl  .px_negative
    cmp rdx, r14     ; сравниваем с width
    jge .px_overflow
    jmp .px_ok
    
.px_negative:
    neg rdx    ; px = -px
    jmp .px_ok
    
.px_overflow:
    mov rdi, r14
    shl rdi, 1   ; 2 * width
    sub rdi, rdx
    dec rdi      ; px = 2 * width - px - 1
    mov rdx, rdi
    
.px_ok:
    ; Вычисляем py = y + ky
    mov rdi, r9
    add rdi, rbx ; py = y + ky
    
    ; Обработка границ для py (зеркальное отражение)
    cmp rdi, 0
    jl  .py_negative
    cmp rdi, r15     ; сравниваем с height
    jge .py_overflow
    jmp .py_ok2
    
.py_negative:
    neg rdi     ; py = -py
    jmp .py_ok2
    
.py_overflow:
    mov rsi, r15
    shl rsi, 1   ; 2 * height
    sub rsi, rdi
    dec rsi      ; py = 2 * height - py - 1
    mov rdi, rsi
    
.py_ok2:
    ; Вычисляем смещение в исходных данных: src_offset = py * row_size + px * 3 + c
    mov  rsi, rdi
    imul rsi, r8  ; py * row_size
    mov  rdi, rdx
    imul rdi, 3   ; px * 3
    add  rsi, rdi ; py * row_size + px * 3
    add  rsi, r11 ; + c
    
    ; Загружаем значение пикселя
    movzx rdi, byte [r12 + rsi]
    
    ; Получаем значение ядра свертки
    ; kernel_index = (ky + 1) * 3 + (kx + 1)
    mov  rsi, rbx
    inc  rsi      ; ky + 1
    imul rsi, 3   ; (ky + 1) * 3
    add  rsi, rcx
    inc  rsi      ; + (kx + 1)
    
    ; Получаем указатель на kernel из стека
    push rdi
    mov  rdi, [rsp + 112]           ; kernel из стека: 8+24+32+48=112 байт
    mov  esi, dword [rdi + rsi * 4] ; kernel[kernel_index] (int = 4 байта)
    pop  rdi
    
    ; Умножаем значение пикселя на ядро и добавляем к сумме
    imul rdi, rsi
    add  rax, rdi
    
    pop rsi
    pop rdi
    pop rdx
    ret