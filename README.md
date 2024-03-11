# my_printf
An implementation of printf on nasm x86-64

# Features
It currently works as a C decl function, so the parameters are passed through stack.

No width or length specifiers are suported, ll is not supported, but is assumed (so all the numbers are 64 bit)
    
Later will be created a function that supports stdcall to make it possible to call myPrintf outside C code.

# Supported specifiers
    * %x - hex
    * %o - oct
    * %b - bin
    * %c - char
