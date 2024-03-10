


all: my_printf

my_printf: my_printf.o
	ld $< -o $@


my_printf.o: my_printf.asm
	nasm -f elf64 -l my_printf.lst $<


