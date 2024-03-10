section .text

global _start

_start:         push qword 0
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
; Supported specifiers: .....
;
;=================================================


_myPrintf:      push rbp
                mov rbp, rsp

                mov rax, 0x01          ; write64
                mov rdi, 1             ; fd = stdout
                mov rsi, [rbp+16]      ; formatStr
                mov rdx, 1             ; 1 character at a time


            myPrintfNextSymbol:
                cmp byte [rsi], 0      
                je myPrintfEnd         ; if (curSymbol == '\0) return

                syscall                ; write64(stdout, &curSymbol, 1)
                inc rsi                ; i++
                jmp myPrintfNextSymbol


            myPrintfEnd:
                pop rbp
                ret




section .data

formatStr db "hello, world", 0x0a, 0x00
