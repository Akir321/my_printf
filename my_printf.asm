section .text

global _start

global myPrintf


%ifdef COMMENT
_start:
                mov rdi, formatStr
                mov rsi, 0x1234
                mov rdx, 0x1234
                mov rcx, 56
                mov r8, 34
                mov r9, -89

                push 12
                push msg

                call myPrintf

                add rsp, 8 * 2   ; release the stack

                mov rax, 0x3c    ; exit
                xor rdi, rdi     ; exit code = 0
                syscall
%endif


%ifdef COMMENT
_start:         
                push rbp
                mov rbp, rsp

                sub rsp, 40
                mov qword [rbp-40], formatStr 
                mov qword [rbp-32], 1234
                mov qword [rbp-24], 0x1111
                mov qword [rbp-16], 0x2222
                mov byte  [rbp-8],  'x'

                call _myPrintf   ; printf(formatStr);

                add rsp, 40
                pop rbp

                mov rax, 0x3c    ; exit
                xor rdi, rdi     ; exit code = 0
                syscall
%endif



;================= myPrintf =====================
; A tramplin for _myPrintf to use it with stdcall

;================================================
;================= CONSTS =======================
sizParam        equ 8
;================================================

myPrintf:
                pop r12               ; r12 = return address

                push r9
                push r8
                push rcx
                push rdx
                push rsi
                push rdi

                call _myPrintf        ; push params and call C decl func

                add rsp, sizParam * 6 ; release the stack
                push r12              ; push back ret addr
                ret



;================ _myPrintf =====================
; C decl function, works exactly like C printf,
; but with few limitations. 
; Parameters are passed through stack
;
; Supported specifiers: %x - hex
;                       %o - oct
;                       %b - bin
;
;=================================================


_myPrintf:      
                push rbp
                mov rbp, rsp

                mov rax, 0x01          ; write64
                mov rdi, 1             ; fd = stdout
                mov rsi, [rbp+16]      ; formatStr
                mov rdx, 1             ; 1 character at a time

                mov r10, rbp
                add r10, 24            ; r10 = ptr to params in stack


            myPrintfNextSymbol:
                cmp byte [rsi], 0      
                je myPrintfEnd         ; if (curSymbol == '\0') return

                cmp byte [rsi], '%'
                je myPrintfParamOut

                syscall                ; write64(stdout, &curSymbol, 1)
                inc rsi                ; rsi++; next symbol
                jmp myPrintfNextSymbol


            myPrintfEnd:
                pop rbp
                ret


        myPrintfParamOut:
                inc rsi                ; rsi++; next symbol
                mov r9, [rsi]
                and r9, 0xff           ; r9 = one symbol
                shl r9, 3              ; r9 *= 8
                jmp myPrintfSpec[r9] 




    myPrintfDefault:
                dec rsi                ; go back 1 symbol
                jmp myPrintfPerPer     ; write % as a symbol

    myPrintfPerPer:
                push rsi
                mov rsi, PercentSymb
                syscall                ; write64(stdout, &"%", 1); => putc(stdout, '%);
                pop rsi

                inc rsi
                jmp myPrintfNextSymbol

    myPrintfPerX:
                mov edi, [r10]         ; edi = num to write
                push rsi
                mov esi, 0x0f          ; mask for last digit (0b1111)
                mov rdx, 4             ; bits of 1 digit
                call printNumBasePow2
                jmp myPrintfPerPow2End ; same instr for all pow2-based specifiers

    myPrintfPerO:
                mov edi, [r10]         ; edi = num to write
                push rsi
                mov esi, 0x07          ; mask for last digit (0b0111)
                mov rdx, 3             ; bits of 1 digit
                call printNumBasePow2
                jmp myPrintfPerPow2End ; same instr for all pow2-based specifiers

    myPrintfPerB:
                mov edi, [r10]         ; edi = num to write
                push rsi
                mov esi, 0x01          ; mask for last digit (0b0001)
                mov rdx, 1             ; bits of 1 digit
                call printNumBasePow2
                jmp myPrintfPerPow2End ; same instr for all pow2-based specifiers

    myPrintfPerC:
                push rsi
                mov rsi, r10           ; rsi = ptr to char to write
                syscall                ; write(stdout, &symbol, 1)

                add r10, sizParam      ; next param
                pop rsi
                inc rsi
                jmp myPrintfNextSymbol

    myPrintfPerS:
                push rsi
                mov rsi, [r10]         ; rsi = str to print

                cld                    ; df = 0; move forward
                mov rdi, rsi           ; rdi = begin of str
                xor cx, cx
                dec cx                 ; cx = 0xffff
                mov al, 0x00           ; al = '\0'
                repne scasb            ; while (--cx && [rdi]!='\0') { rdi++ };
                sub rdi, rsi           ; rdi = strlen(str)

                mov rax, 1             ; write64
                mov rdx, rdi           ; rdx = strlen
                mov rdi, 1             ; stdout
                syscall                ; write64(stdout, str, strlen(str));

                add r10, sizParam      ; nextParam
                pop rsi
                inc rsi                ; nextSymbol
                mov rax, 1
                mov rdx, 1
                jmp myPrintfNextSymbol
                

    myPrintfPerPow2End:
                pop rsi
                inc rsi                ; nextSymbol
                add r10, sizParam      ; nextParam;
                mov rax, 1             ; write64()
                mov rdx, 1             ; rdx = 1 (for writing one byte in syscall write)
                jmp myPrintfNextSymbol

    myPrintfPerD:
                mov r8, NumBufEnd          ; r8  = ptr to the right of NumBuf
                mov eax, [r10]             ; edx:eax = num to write
                cmp eax, 0
                push 0                     ; local var for sign
                jns printPerDNextDigit     ; if (num >= 0) evaluate digits
                inc byte [rsp]            
                neg eax                    ; if (num < 0) { numSign = 1; num = -num; }


            printPerDNextDigit:            ; do {} while (num != 0);
                xor edx, edx               ; edx = 0
                dec r8                     ; NumBuf--;

                mov r9, 10                 ; r9 = 10 -> base
                div r9d                    ; rax = curNum / 10; rdx = curNum % 10                   
                mov dl, Digits[edx]        ; dl = curDigit symbol
                mov byte [r8], dl          ; write curDigit in mem (NumBuf)
                cmp eax, 0
                jne printPerDNextDigit     ; if (number == 0) break;

                cmp dword [rsp], 0
                je printPerDWrite          ; if (sign == 0) write num
                dec r8
                mov byte [r8], '-'         ; if (sign == 1) write '-' symbol


            printPerDWrite:
                mov rax, 0x01              ; write64()
                mov rdi, 1                 ; fd  = stdout
                push rsi
                mov rsi, r8                ; buf = NumBuf (from last written digit)
                mov rdx, NumBufEnd         
                sub rdx, r8                ; rdx = amount of digits
                syscall                    ; write64(stdout, NumBuf, len(num));

                pop rsi
                add rsp, 8                 ; release the sign var
                mov rdx, 1
                mov rax, 1
                inc rsi
                add r10, sizParam
                jmp myPrintfNextSymbol



;======================= printNumBasePow2 ===========================
; Prints a number in a pow2-system (bin, oct, hex)
; 
; Param:  edi = number to print
;         esi = bit mask to get the lowest digit (depends on base)
;         rdx = amount of bits to shift (amount of 1 bits in rsi)
;
; Exit:   None
;
; Destr:  rax, rdi, rsi, rdx, r8, r9, cl
;=====================================================================

printNumBasePow2:
                mov r8, NumBufEnd          ; r8 = ptr to the right of NumBuf
                mov cl, dl                 ; cl = amount of bits to shift


            printNBP2NextDigit:            ; do {} while (num != 0);
                dec r8                     ; NumBuf--;
                mov eax, edi               ; eax = curNum
                and eax, esi               ; eax = curDigit value
                mov eax, Digits[eax]       ; eax = curDigit symbol
                mov byte [r8], al          ; write curDigit in mem (NumBuf)

                shr edi, cl                ; edi /= base
                jne printNBP2NextDigit     ; if (number == 0) break;


            printNBP2Write:
                mov rax, 0x01              ; write64()
                mov rdi, 1                 ; fd  = stdout
                mov rsi, r8                ; buf = NumBuf (from last written digit)
                mov rdx, NumBufEnd         
                sub rdx, r8                ; rdx = amount of digits
                syscall                    ; write64(stdout, NumBuf, len(num));

                ret



section .data

NumBuf          db 0 dup (64)
NumBufEnd       db 0
NumBufLen       equ NumBufLen - NumBuf
                


section .rodata

formatStr       db "%x %o hi %o %x %d %s %x", 0x0a, 0x00

msg             db "hello", 0x00

Digits          db '0123456789abcdef'
PercentSymb     db '%'


;=========================== printf specifiers jmp table =============================

myPrintfSpec    dq '%' dup(myPrintfDefault)                          ; start
myPrintfSpecPer dq myPrintfPerPer,  ('a'-'%'-1) dup(myPrintfDefault) ; %% - symbol '%'
myPrintfSpecA   dq myPrintfDefault                                   ; start of digits
myPrintfSpecB   dq myPrintfPerB                                      ; %b - bin
myPrintfSpecC   dq myPrintfPerC                                      ; %c - char
myPrintfSpecD   dq myPrintfPerD,    ('o'-'d'-1) dup(myPrintfDefault) ; %d - decimal (int)
myPrintfSpecO   dq myPrintfPerO,    ('s'-'o'-1) dup(myPrintfDefault) ; %o - oct
myPrintfSpecS   dq myPrintfPerS,    ('x'-'s'-1) dup(myPrintfDefault) ; %s - str
myPrintfSpecX   dq myPrintfPerX,    (256-'x'-1) dup(myPrintfDefault) ; %x - hex

;======================================================================================
