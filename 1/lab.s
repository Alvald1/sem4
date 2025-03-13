bits    64
;       res=a*(e-b)*c/(e+d)-(d+b)/e
section .data

a:
        dd      214783647
b:
        dw      -32767
c:
        dd      214483
d:
        dw      0
e:
        dd      1
section .text
global  _start
_start:
        mov     r8d, dword [a]
        movsx   r9d, word [b]
        mov    r10d, dword [c]
        movsx   r11d, word [d]
        mov     r12d, dword [e]

        test    r12d, r12d     ;Check if r12d [e] is zero
        jz      div_zero_error

        mov     eax, r12d      ;r12d [e] -> eax
        sub     eax, r9d       ;eax - r9d [b] -> eax

        jo      overflow_error
     
        imul    r8d            ;r8d [a] * eax -> edx:eax  

        ; Move 64-bit result from edx:eax to r13
        shl     rdx, 32
        mov     r13d, eax
        or      r13, rdx    
                       
        mov     ebx, r12d      ;r12d [e] -> ebx
        add     ebx, r11d      ;ebx + r11d [d] -> ebx

        jo      overflow_error

        test    ebx, ebx       ;Check if ebx is zero
        jz      div_zero_error       
        
        mov     eax, r10d      ;r10d [c] -> eax 

        cdq
        idiv    ebx            ;eax / ebx -> eax, eax % ebx -> edx

        imul    r13            ;r13 * rax -> rdx:rax       
        
        mov     r8, rdx        ;rdx -> r8
        mov     r10, rax       ;rax -> r10

        mov     eax, r11d      ;r11d [d] -> eax           
        add     eax, r9d       ;eax + r9d [b] -> eax    

        jo      overflow_error        
        
        cdq                     
        idiv    r12d           ;eax / r12d [e] -> eax, eax % r12d [e] -> edx                
        
        
        ; Implement subtraction of r8:r10 - rax
        cdqe
        ; Проверяем: rax > r10 и они одного знака?
        cmp     r10, rax       ; Сравниваем r10 и rax
        jae     do_subtraction ; Если r10 >= rax, переходим к вычитанию
        
        ; Проверяем, одного ли знака числа
        mov     rcx, r10       ; Копируем r10 в rcx
        xor     rcx, rax       ; XOR выявит разницу в знаках
        js      do_subtraction ; Если старший бит = 1 (разные знаки), пропускаем dec r8
        
        dec     r8             ; Если r10 < rax (т.е. rax > r10) и одного знака, уменьшаем r8
        
do_subtraction:
        sub     r10, rax       ; r10 - rax -> r10
        jno     L1             ; Если нет переполнения, переходим к L1
        inc     r8             ; Если было переполнение, увеличиваем r8

L1:     
        
        ; Result in r8:r10     
        ; python print(int(gdb.parse_and_eval("$r8")) * (2**64) + int(gdb.parse_and_eval("$r10")))                  
        mov     eax, 60
        mov     edi, 0
        syscall
        
div_zero_error:
        mov     eax, 60
        mov     edi, 1
        syscall

overflow_error:
        mov     eax, 60
        mov     edi, 2
        syscall