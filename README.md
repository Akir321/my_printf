# my_printf
An implementation of printf on Nasm x86-64 (for Linux)

# Features
It works as a C decl function, so the parameters are passed through stack.

No width or length specifiers are supported, ll is not supported.
    
To use it in C code with stdcall there is a function `myPrintf` that pushes the 6 registers to stack (rdi, rsi, rdx, rcx, r8, r9), providing a C decl call for `_myPrintf`

# Why it uses little calls and many jumps?

There is a mechanism in modern **CPU** to that provides faster computing, it is called **pipelining**. The idea of it is multitasking. Different blocks of instructions are separated into pieces, and the **CPU** works with them separately.

On the first tick it works with stage 1 of the first block of instructions. On the second tick --- with stage 2 of the first block and stage 1 of the second block. And so on.

For this system to function, the **CPU** has to correctly predict where the next instruction is going to be. Even more, it has to predict it without finishing all the blocks of instructions it is working on.

Now let's consider, what `ret` does. It takes the return address from the stack. But the stack can change a lot after performing several instructions. It means that we have to wait for the instructions to end before returning from a function.

On the other hand, `jmp` doesn't depend on any instructions, its behavior is pre-determined (because in modern OS most of the times we cannot modify the binary code while it is being executed). So the **CPU** can easily predict the address of the next instruction.

This makes using `jmp` instead of `ret` **pipeline-friendly**. Such a program will likely work faster than a non-pipeline-friendly one.

# Supported specifiers
    * %x - hex
    * %o - oct
    * %b - binary
    * %c - char
    * %d - decimal
    * %s - null-terminated str
