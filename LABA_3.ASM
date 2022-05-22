.model small
.stack  256
.data
 
Rows            equ    5                ;������������ ���������� �����
Columns         equ    6                ;������������ ���������� ��������
myMatrixSize    equ    Rows*Columns     ;������������ ������ �������
 
m               dw     Rows                    ;������� ���������� �����
n               dw     Columns                 ;������� ���������� ��������
Matrix          dw     myMatrixSize dup(0)     ;�������
 
NewLine         db     0dh, 0ah, '$'   ;"������� ������"
msInput         db     'Input matrix', '$'
msCurrent       db     'Current matrix', '$' 


str_len         equ    $-msResult
my_str          db     str_len dup (?)  

msResult        db     'Result: ','$'
asPrompt1       db     'element[', '$'      ;������ �����������
asPrompt2       db     ',', '$'
asPrompt3       db     ']= ', '$'   

not_memory      db     'ERROR: overflow','$'

Min             dw      -32768
 
kbMinLen        equ     6+1             ;����� ����� � ���������� Fn 0ah
kbInput         db      kbMinLen,kbMinLen dup(0)
 
.code 
 
; �������������� ������ � �����
; �� �����:
; ds:[si] - ������ � ������
; ds:[di] - ����� �����
; �� ������
; ds:[di] - �����
; CF - ���� �������� (��� ������ - ����������, ����� - �������)
StringInNumber PROC
        push    ax
        push    bx
        push    cx
        push    dx
        push    ds
        push    es
        push    si
        push    ds
        pop     es
 
        mov     cl, ds:[si]
        xor     ch, ch
 
        inc     si
 
        mov     bx, 10
        xor     ax, ax
 
        ;���� � ������ ������ ������ '-'
        ; - ������� � ����������
        ; - ��������� ���������� ��������������� ��������
        cmp     [si], '-'
        jne     Conversion
        inc     si
        dec     cx
Conversion:
        mul     bx         ; �������� ax �� 10 ( dx:ax=ax*bx )
        mov     [di], ax   ; ���������� ������� �����
        cmp     dx, 0      ; ���������, ��������� �� ������������
        jnz     Error
        mov     al, [si]   ; ����������� ��������� ������ � �����
        cmp     al, '0'
        jb      Error
        cmp     al, '9'
        ja      Error
        sub     al, '0'
        xor     ah, ah
        add     ax, [di]
        jc      Error    
        cmp     ax, 8000h  ;32768
        ja      Error
        inc     si
 
        loop    Conversion
 
        pop     si         ;�������� �� ����
        push    si
        inc     si
        cmp     byte ptr [si], '-'
        jne     Check    ;���� ������ ���� �������������
        neg     ax       ;���� ������ ���� �������������
        jmp     SavingResult
Check:                   ;�������������� ��������, ����� ��� ����� �������������� ����� �������� �������������
        or      ax, ax   
        js      Error
SavingResult:            ;��������� ���������
        mov     [di], ax
        clc
        pop     si
        pop     es
        pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
Error:
        xor     ax, ax
        mov     [di], ax
        stc
        pop     si
        pop     es
        pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
StringInNumber ENDP
 
; ������� ����� �� �������� AX �� �����
; ������� ������:
; ax - ����� ��� �����������
Show_AX proc
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
 
        mov     cx, 10
        xor     di, di          ; di - ���. ���� � �����
 
        ; ���� ����� � ax �������������, ��
        ;1) ���������� '-'
        ;2) ������� ax �������������
        or      ax, ax
        jns     NoNumberSign
        push    ax
        mov     dx, '-'
        mov     ah, 2           ; ah - ������� ������ ������� �� �����
        int     21h
        pop     ax
 
        neg     ax
 
NoNumberSign:
        xor     dx, dx
        div     cx              ; dl = num mod 10
        add     dl, '0'         ; ������� � ���������� ������
        inc     di
        push    dx              ; ���������� � ����
        or      ax, ax
        jnz     NoNumberSign
        ; ������� �� ����� �� �����
Show:
        pop     dx              ; dl = ��������� ������
        mov     ah, 2           ; ah - ������� ������ ������� �� �����
        int     21h
        dec     di              ; ��������� ���� di<>0
        jnz     Show
 
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
Show_AX endp
 
; �� �����
;m     - ���������� �����
;n     - ���������� ��������
;ds:dx - ����� �������
ShowMatrix PROC 
        pusha
        mov     si, 0  ; ������
        mov     di, 0  ; �������
        mov     bx, dx
 
ShowRow:
        mov     ax, [bx]
        call    Show_AX
 
        mov     ah, 02h
        mov     dl, ' '
        int     21h
 
        add     bx, 2
 
        inc     di
 
        cmp     di, n
        jb      ShowRow
 
        mov     dx, OFFSET NewLine
        mov     ah, 09h
        int     21h
 
        mov     di, 0 
        inc     si 
        cmp     si, m
        jb      ShowRow
 
        popa
        ret
ShowMatrix ENDP
 
; �� �����
;ds:dx - ����� �������
InputMatrix PROC
        pusha
        ;bx - ����� ���������� �������� �������
        mov     bx, dx
        ;����� �� ����� ����������� ������ �������
        mov     ah, 09h
        mov     dx, OFFSET msInput
        int     21h
 
        mov     ah, 09h
        mov     dx, OFFSET NewLine
        int     21h
 
        mov     si, 1  ; ������ (������)
        mov     di, 1  ; ������� (������)
InpInt:   
        mov     ah, 09h
        mov     dx, OFFSET NewLine
        int     21h
        ;����� �� ����� ����������� 'a[1,1]='
        lea     dx, asPrompt1
        mov     ah, 09h
        int     21h
        mov     ax,     si
        call    Show_AX
        lea     dx, asPrompt2
        mov     ah, 09h
        int     21h
        mov     ax,     di
        call    Show_AX
        lea     dx, asPrompt3
        mov     ah, 09h
        int     21h
 
        ;���� ������
        mov     ah, 0ah
        mov     dx, OFFSET kbInput
        int     21h
 
        ;�������������� ������ � �����
        push    di
        push    si
        mov     si, OFFSET kbInput+1
        mov     di, bx
        call    StringInNumber
        pop     si
        pop     di
        jc      InpInt  ; ���� ������ �������������� - ��������� ����
        
        cmp     word ptr [bx],  32767
        jle     YetTest
        jmp     InpInt
YetTest:
        cmp     word ptr [bx],  -32768
        jge     AllGood
        jmp     InpInt
AllGood:
        ;�� ������ - ������� � ��������� ������
        mov     dx, OFFSET NewLine
        mov     ah, 09h
        int     21h
        ;������� � ���������� �������� �������
        add     bx, 2 
        inc     di 
        cmp     di, n
        jbe     InpInt 
        mov     di, 1 
        inc     si 
        cmp     si, m
        jbe     InpInt 
        popa
        ret
InputMatrix ENDP 




error_message proc
        mov     dx, OFFSET not_memory
        mov     ah, 09h
        int     21h
        mov     ax, 4c00h
        int     21h
    ENDP

 
Main:
        mov     dx, @data
        mov     ds, dx
 
        mov     dx, OFFSET Matrix
        call    InputMatrix
 
        mov     ah, 09h
        mov     dx, OFFSET msCurrent
        int     21h
 
        mov     ah, 09h
        mov     dx, OFFSET NewLine
        int     21h
 
        mov     dx, OFFSET Matrix
        call    ShowMatrix
        
        
        
        
        ;����� ����������� ����� � ��������
        mov     ax, 7FFFh   ;������������ �������� ����� � �������
        mov     dx, n       ;���������� �������� ������ ��� ��������
        shl     dx, 1       ;� ���������� �������� �������
        mov     cx, n
        lea     si, Matrix   
        

ForJ:                   ;���� �� �������
        mov     bx, 0   ;����� ��������� �������
        push    cx
        mov     cx, m   ;���������� ��������� � �������
        push    si
        ForI:
                add     bx, [si]
                 jo     error_message        
                add     si, dx  
               
                loop    ForI       
        pop     si
        pop     cx
 
        cmp     ax, bx
        jle     Next
        mov     ax, bx 
        mov     [Min], ax
Next:
        add     si, 2
        loop    ForJ  
        
;����� ����������� �� �����  ==================================================================================== 
            
        pushf        
        pusha     
        xor     cx, cx
        xor     si, si
        xor     di, di
        mov	    cx, str_len
        lea	    si, msResult
        lea	    di, my_str
        rep	movsb    
        ;========================================================================================================
          
        popa
        popf

        mov     ah, 09h
        mov     dx, OFFSET my_str
        int     21h
 
        mov     ah, 09h
        mov     dx, OFFSET NewLine
        int     21h     
            
;����� �������� � ����������� ������ � ��������
        
        mov     di, 0       ;����� ������� � ������������ ������
        mov     dx, n       ;���������� �������� ������ ��� ��������
        shl     dx, 1       ;� ���������� �������� �������
        mov     cx, n
        lea     si, Matrix   
        

ForJ2:                      ;���� �� �������
        mov     bx, 0       ;����� ��������� �������
        push    cx
        mov     cx, m       ;���������� ��������� �
        push    si
       ForI2:
                add     bx, [si]
                add     si, dx
                loop    ForI2
        pop     si
        pop     cx
 
        cmp     [Min], bx
        jne     Next2
      
        mov     di, n       ;di - ����� ������� � ������������ ������
        sub     di, cx  
        
        mov     ax, di
        inc     ax
                                   
        pushf        
        pusha
        
        add ax, 48
        mov dx, ax
        mov ah,02h
        int 21h
        
        
        mov     ah, 09h
        mov     dx, OFFSET NewLine
        int     21h
        popa
        popf
                             
Next2:
        add     si, 2
        loop    ForJ2        


ExitFromProg:        
        mov     ax, 4c00h
        int     21h
         
END     Main