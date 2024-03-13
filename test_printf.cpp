#include <stdio.h>

extern "C" void myPrintf(...);

int main()
{
    //unsigned a = 0x1234;

    puts("C printf:");
    printf("%x %o hi %o %x %d %c %x\n", 0x1234, 0x1234, 56, 34, -89, 98, 12);

    puts("myPrintf:");
    myPrintf("%x %o hi %o %x %d %c %x\n", 0x1234, 0x1234, 56, 34, -89, 98, 12);
}
