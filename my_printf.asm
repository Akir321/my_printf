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
                mov rdi, [r10]         ; rdi = num to write
                add r10, 8             ; nextParam;
                push rsi
                mov rsi, 0x0f          ; mask for last digit
                mov rdx, 4             ; bits of 1 digit
                call printNumBasePow2
                jmp myPrintfPerPow2End ; same instr for all pow2-based specifiers


    myPrintfPerPow2End:
                pop rsi
                inc rsi                ; nextSymbol
                mov rax, 1             ; write64()
                mov rdx, 1             ; rdx = 1 (for writing one byte in syscall write)
                jmp myPrintfNextSymbol



;======================= printNumBasePow2 ===========================
; Prints a number in a pow2-system (bin, oct, hex)
; 
; Param:  rdi = number to print
;         rsi = bit mask to get the lowest digit (depends on base)
;         rdx = amount of bits to shift (amount of 1 bits in rsi)
;
; Exit:   None
;
; Destr:  rax, rdi, rsi, rdx, r8, r9, cl
;=====================================================================

printNumBasePow2:
                mov r8, NumBufEnd          ; r8 = ptr to the right of buf
                mov cl, dl                 ; cl = amount of bits to shift


            printNBP2NextDigit:            ; do {} while (num != 0);
                dec r8                     ; NumBuf--;
                mov r9, rdi                ; r9 = curNum
                and r9, rsi                ; r9 = curDigit value
                mov r9, Digits[r9]         ; r9 = curDigit symbol
                mov byte [r8], r9b         ; write curDigit in mem (NumBuf)

                shr rdi, cl                ; rdi /= base
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
