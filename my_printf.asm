section .text

global _start

_start:         push qword 0x1234
                push formatStr
                call _myPrintf   ; printf(formatStr);

                mov rax, 0x3c    ; exit
                xor rdi, rdi     ; exit code = 0
                syscall



;================ _my_printf =====================
; C decl function, works exactly like C printf,
; but with few limitations. 
; Parameters are passed through stack
;
; Supported specifiers: %h - for hex
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
                je myPrintfEnd         ; if (curSymbol == '\0) return

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
                sub r9, '%'
                shl r9, 3              ; r9 *= 8
                jmp myPrintfSpecPer[r9] 




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
                mov cl, 60d            ; 60d bits = 15 hex digits to shift        

            wrXNextByte:
                mov r8, [r10]          ; r8 = qword
                shr r8, cl             ; SI /= 16^(CX/4)
                and r8, 0x0f           ; SI = digit value

                push rcx 
                push rsi
                mov rsi, Digits
                add rsi, r8            ; rsi = ptr to needed digit
                syscall                ; write(curDigit)
                pop rsi 
                pop rcx
                
                sub cl, 4              ; CL -= 4 
                jns wrXNextByte        ; if (CL >= 0) repeat
                

                inc rsi                ; next symbol
                inc r10                ; next param
                jmp myPrintfNextSymbol



section .rodata

formatStr       db "%x = hello, world", 0x0a, 0x00

Digits          db '0123456789abcdef'
PercentSymb     db '%'


;=============== printf specifiers jmp table =======================

myPrintfSpec    dq 37 dup(myPrintfDefault)
myPrintfSpecPer dq myPrintfPerPer, 59 dup(myPrintfDefault)
; '%%' - symbol '%'
myPrintfSpecA   dq 23 dup(myPrintfDefault), myPrintfPerX 
; '%x' - hex

;====================================================================
