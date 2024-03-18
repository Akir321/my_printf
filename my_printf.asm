section .text

global _start

global myPrintf

;==================================== MACRO ==============================


; assuming that: al  = (symb) --        symbol to write
;                rdi = (dest) -- ptr to where  to write
%macro writeToBuf 0
                cmp rdi, outBufEnd
                jne %%skip
                call flushBuffer         ; if (rdi == outBufEnd) flushBuf();

%%skip:         stosb

%endmacro

;=========================================================================

%ifdef COMMENT
_start:
                mov rdi, formatStr
                mov rsi, 0x1234
                mov rdx, 0x1234
                mov rcx, 56
                mov r8, 34
                mov r9, -89


                push 30
                push 33
                push 100
                push 3802
                push love
                push -1
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
;                       %d - dec
;                       %c - char
;                       %s - str
;
;=================================================


_myPrintf:      
                push rbp
                mov rbp, rsp
                
                cld                    ; df = 0 -> move forwards
                mov rdi, outBuf        ; ptr to buffer in mem
                mov rsi, [rbp+16]      ; formatStr
                mov r10, rbp
                add r10, 24            ; r10 = ptr to params in stack


            myPrintfNextSymbol:
                lodsb                  ; al = [rsi++] -> al = curSymbol

                cmp al, 0      
                je myPrintfEnd         ; if (curSymbol == '\0') return;

                cmp al, '%'
                je myPrintfParamOut    ; if (curSymbol == '%')  writeParam;

                writeToBuf             ; write symbol (al), flush if needed
                jmp myPrintfNextSymbol


            myPrintfEnd:
                call flushBuffer       ; flush outBuf before exit
                pop rbp
                ret


        myPrintfParamOut:
                lodsb                  ; al  = [rsi++] -> al = curSymbol
                                       ; al  = symbol after '%'
                and rax, 0xff          ; rax = one symbol
                cmp al, '%'            
                jl myPrintfDefault     ; if (curSymb < '%') default
                cmp al, 'x'            
                ja myPrintfDefault     ; if (curSymb > 'x') default

                sub rax, '%'           ; rax -= '%'
                shl rax, 3             ; rax *= addrSize
                jmp myPrintfSpec[rax]  ; switch(curSymbol)



    myPrintfDefault:
                dec rsi                ; go back 1 symbol
                jmp myPrintfPerPer     ; write % as a symbol

    myPrintfPerPer:
                mov al, '%'            ; al = '%' <- symbol to write
                writeToBuf             ; write symbol (al), flush if needed
                jmp myPrintfNextSymbol

    myPrintfPerX:
                push rsi
                mov esi, [r10]         ; esi = num to write
                mov rdx, 0x0f          ; mask for last digit (0b1111)
                mov cl, 4              ; bits of 1 digit
                jmp printNumBasePow2

    myPrintfPerO:
                push rsi
                mov esi, [r10]         ; esi = num to write
                mov edx, 0x07          ; mask for last digit (0b0111)
                mov cl, 3              ; bits of 1 digit
                jmp printNumBasePow2

    myPrintfPerB:
                push rsi
                mov esi, [r10]         ; edi = num to write
                mov edx, 0x01          ; mask for last digit (0b0001)
                mov cl, 1              ; bits of 1 digit
                jmp printNumBasePow2

    myPrintfPerC:
                mov al, [r10]          ; al = symbol to write
                add r10, sizParam      ; next param
                writeToBuf             ; flush outBuf if needed, write symbol (al)
                jmp myPrintfNextSymbol

    myPrintfPerS:
                push rsi
                mov rsi, [r10]         ; rsi = str to print

            printStrNextSymbol:
                lodsb                  ; al = [rsi++] <- curSymbol
                cmp al, 0x00           ; if (curSymbol == '\0') break;
                je myPrintfPerSEnd
                writeToBuf             ; flush outBuf if needed, write symbol (al)
                jmp printStrNextSymbol
                
            myPrintfPerSEnd:
                add r10, sizParam      ; nextParam
                pop rsi
                jmp myPrintfNextSymbol
                

    myPrintfPerPow2End:
                pop rsi
                add r10, sizParam      ; nextParam;
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
                push rsi
                mov rsi, r8                ; rsi = numBuf

            printPerDWriteNext:
                cmp rsi, NumBufEnd         ; if (&curSymb == NumBufEnd) break
                je printPerDEnd

                lodsb                      ; al = [rsi++] <- symbol to write
                writeToBuf                 ; flush outBuf if needed, write symbol (al)
                jmp printPerDWriteNext

                
            printPerDEnd:
                pop rsi
                add rsp, 8                 ; release the sign var
                add r10, sizParam
                jmp myPrintfNextSymbol



;======================= printNumBasePow2 ===========================
; Prints a number in a pow2-system (bin, oct, hex)
;
; WARNING: It is not a function, as it ends with a jump
;          This is to make it more pipeline-friendly
; 
; Param:  rdi = dest (void *)
;         esi = number to print
;         edx = bit mask to get the lowest digit (depends on base)
;          cl = amount of bits to shift (amount of 1 bits in rsi)
;
; Exit:   None
;
; Destr:  rax, rdi, rsi, rdx, r8, r9, cl
;=====================================================================

printNumBasePow2:
                mov r8, NumBufEnd          ; r8 = ptr to the right of NumBuf

            printNBP2NextDigit:            ; do {} while (num != 0);
                dec r8                     ; NumBuf--;
                mov eax, esi               ; eax = curNum
                and eax, edx               ; eax = curDigit value
                mov eax, Digits[eax]       ; eax = curDigit symbol
                mov byte [r8], al          ; write curDigit in mem (NumBuf)

                shr esi, cl                ; esi /= base
                jne printNBP2NextDigit     ; if (number == 0) break;


            ; write num to outBuf
                mov rsi, r8                ; buf = NumBuf (from last written digit)
                xor cx, cx
                dec cx                     ; cx = 0xffff

            printNBP2WriteNextSymb:
                lodsb                      ; al = [rsi++] -> al = curSymbol
                writeToBuf                 ; flush outBuf if needed, write symbol (al)
                cmp rsi, NumBufEnd         ; do {} while (rsi != NumBufEnd)
                loopne printNBP2WriteNextSymb

                jmp myPrintfPerPow2End     ; same instr for all pow2-based specifiers


;========================= flushBuffer ===========================
; A funtion that writes my output buffer to stdout and sets
; register values according to the logic of program
;
; Enter: rdi = ptr to end of buf
;                     beg of buf is outBuf
;
; Exit:  rdi = outBuf
;
; Destr: rax, rdi, rdx
;=================================================================


flushBuffer:
                push rdi
                push rsi

                mov rax, 1        ; write64
                mov rsi, outBuf   ; rsi = ptr to str
                mov rdx, rdi
                sub rdx, rsi      ; rdx = count
                mov rdi, 1        ; fd = stdout
                syscall           ; write64(stdout, outBuf, count)

                pop rsi
                pop rdi
                mov rdi, outBuf   ; write from the start of outbuf

                ret 






section .data

bufSize         equ 64
maxNDigits      equ 64

NumBuf          db maxNDigits dup(0)
NumBufEnd       db 0
NumBufLen       equ NumBufLen - NumBuf

outBuf          db bufSize dup(0)
outBufEnd:      db 0
                


section .rodata

formatStr       db "%x %o hi %o %x %% %r %d %s", 0x0a, "%d %s %x %d%%%c%b", 0x0a, 0x00

msg             db "hello", 0x00
love            db "love",  0x00

Digits          db '0123456789abcdef'
PercentSymb     db '%'


;=========================== printf specifiers jmp table =============================

; start
align 8
myPrintfSpec    dq myPrintfPerPer,  ('b'-'%'-1) dup(myPrintfDefault) ; %% - symbol '%'
myPrintfSpecB   dq myPrintfPerB                                      ; %b - bin
myPrintfSpecC   dq myPrintfPerC                                      ; %c - char
myPrintfSpecD   dq myPrintfPerD,    ('o'-'d'-1) dup(myPrintfDefault) ; %d - decimal (int)
myPrintfSpecO   dq myPrintfPerO,    ('s'-'o'-1) dup(myPrintfDefault) ; %o - oct
myPrintfSpecS   dq myPrintfPerS,    ('x'-'s'-1) dup(myPrintfDefault) ; %s - str
myPrintfSpecX   dq myPrintfPerX,                                     ; %x - hex

;======================================================================================
