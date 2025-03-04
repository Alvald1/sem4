bits    64
;       res=a*(e-b)*c/(e+d)-(d+b)/e
section .data
res:
        dq      0
a:
        dd      40
b:
        dw      32767
c:
        dd      2
d:
        dw      32767
e:
        dd      30
section .text
global  _start
_start:
        mov     eax, dword [e]       
        movsx   ebx, word [b]        
        sub     eax, ebx   

        mov     ecx, dword [a]      
        imul    ecx      
        
        jo      overflow_error
        
        mov     ecx, dword [c]       
        imul    ecx              
        
        jo      overflow_error
        
        mov     ecx, dword [e]       
        movsx   esi, word [d]        
        add     ecx, esi            
        
        or      ecx, ecx
        jz      div_zero_error                 
        
        cdq                     
        idiv    ecx                
        
        mov     esi, eax           
        
        movsx   eax, word [d]        
        movsx   ebx, word [b]        
        add     eax, ebx            
        cdq                         
        
        mov     ecx, dword [e]       
        or      ecx, ecx
        jz      div_zero_error                 
        
        idiv    ecx                 
        
        sub     esi, eax            
               
        movsx   rsi, esi            
        mov     qword [res], rsi     
        
        mov     eax, 60
        xor     edi, edi
        syscall
        
div_zero_error:
        mov     eax, 60
        mov     edi, 1
        syscall

overflow_error:
        mov     eax, 60
        mov     edi, 2
        syscall