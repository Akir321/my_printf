section .text

global _start

_start:         
                push rbp
                mov rbp, rsp

                sub rsp, 40
                mov qword [rbp-40], formatStr 
                mov qword [rbp-32], 0x2222
                mov qword [rbp-24], 0x1111
                mov qword [rbp-16], 0x1234
                mov byte  [rbp-8],  'x'

                call _myPrintf   ; printf(formatStr);

                add rsp, 40
                pop rbp

                mov rax, 0x3c    ; exit
                xor rdi, rdi     ; exit code = 0
                syscall



;================ _my_printf =====================
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
                push rsi
                mov rsi, 0x0f          ; mask for last digit (0b1111)
                mov rdx, 4             ; bits of 1 digit
                call printNumBasePow2
                jmp myPrintfPerPow2End ; same instr for all pow2-based specifiers

    myPrintfPerO:
                mov rdi, [r10]         ; rdi = num to write
                push rsi
                mov rsi, 0x07          ; mask for last digit (0b0111)
                mov rdx, 3             ; bits of 1 digit
                call printNumBasePow2
                jmp myPrintfPerPow2End ; same instr for all pow2-based specifiers

    myPrintfPerB:
                mov rdi, [r10]         ; rdi = num to write
                push rsi
                mov rsi, 0x01          ; mask for last digit (0b0001)
                mov rdx, 1             ; bits of 1 digit
                call printNumBasePow2
                jmp myPrintfPerPow2End ; same instr for all pow2-based specifiers

    myPrintfPerC:
                push rsi
                mov rsi, r10           ; rsi = ptr to char to write
                syscall                ; write(stdout, &symbol, 1)

                add r10, 8             ; next param
                pop rsi
                inc rsi
                jmp myPrintfNextSymbol





    myPrintfPerPow2End:
                pop rsi
                inc rsi                ; nextSymbol
                add r10, 8             ; nextParam;
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

formatStr       db "%x %o %b %c = hello, world", 0x0a, 0x00

Digits          db '0123456789abcdef'
PercentSymb     db '%'


;=========================== printf specifiers jmp table =============================

myPrintfSpec    dq '%' dup(myPrintfDefault)                          ; start
myPrintfSpecPer dq myPrintfPerPer,  ('a'-'%'-1) dup(myPrintfDefault) ; %% - symbol '%'
myPrintfSpecA   dq myPrintfDefault                                   ; start of digits
myPrintfSpecB   dq myPrintfPerB                                      ; %b - bin
myPrintfSpecC   dq myPrintfPerC                                      ; %c - char
myPrintfSpecD   dq myPrintfDefault, ('o'-'d'-1) dup(myPrintfDefault) ; %d
myPrintfSpecO   dq myPrintfPerO,    ('x'-'o'-1) dup(myPrintfDefault) ; %o - oct
myPrintfSpecX   dq myPrintfPerX,    (256-'x'-1) dup(myPrintfDefault) ; %x - hex

;======================================================================================
