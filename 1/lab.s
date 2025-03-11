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
        
        cdqe
        ; Implement subtraction of r8:r10 - eax
        sub     r10, rax       ;r10 - rax -> r10

        jo      overflow_error
        
        sbb     r8, 0          ;r8 - 0 - CF -> r8 
        
        jo      overflow_error      
        
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