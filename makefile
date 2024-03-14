CXX = gcc
CXX_FLAGS = -Wshadow -Winit-self -Wredundant-decls -Wcast-align -Wundef -Wfloat-equal -Winline\
 -Wunreachable-code -Wmissing-declarations -Wmissing-include-dirs -Wswitch-enum -Wswitch-default\
 -Weffc++ -Wmain -Wextra -Wall -g -pipe -fexceptions -Wcast-qual -Wconversion -Wctor-dtor-privacy\
 -Wempty-body -Wformat-security -Wformat=2 -Wignored-qualifiers -Wlogical-op\
 -Wno-missing-field-initializers -Wnon-virtual-dtor -Woverloaded-virtual\
 -Wpointer-arith -Wsign-promo -Wstack-usage=8192 -Wstrict-aliasing\
 -Wstrict-null-sentinel -Wtype-limits -Wwrite-strings -Werror=vla -D_DEBUG\
 -D_EJUDGE_CLIENT_SIDE 



all: my_printf

complink: test_printf.cpp my_printf.o
	$(CXX) $< my_printf.o -o $@ $(CXX_FLAGS)

test_my_printf: my_printf.o test_printf.o
	$(CXX) -no-pie $< test_printf.o -o $@ 


my_printf: my_printf.o
	ld $< -o $@


my_printf.o: my_printf.asm
	nasm -f elf64 -l my_printf.lst $<

test_printf.o: test_printf.cpp
	$(CXX) -c $< -o $@ $(CXX_FLAGS) 

test_printf.s: test_printf.cpp
	$(CXX) -S test_printf.cpp -o test_printf.s

clear:
	rm *.o *.out *.lst


