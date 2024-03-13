# my_printf
An implementation of printf on nasm x86-64

# Features
It currently works as a C decl function, so the parameters are passed through stack.

No width or length specifiers are suported, ll is not supported
    
To use it in C code there is a function `myPrintf` that pushes the 6 registers to stack, providing a C decl call for `_myPrintf`

# Supported specifiers
    * %x - hex
    * %o - oct
    * %b - binary
    * %c - char
    * %d - decimal
