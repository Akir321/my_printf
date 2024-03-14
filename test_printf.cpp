#include <stdio.h>

extern "C" void myPrintf(...);

int main()
{
    //unsigned a = 0x1234;

    const char *msg = "man";

    puts("C printf:");
    printf("%x %o hi %o %x %d %s %x\n", 0x1234, 0x1234, 56, 34, -89, msg, 12);

    puts("myPrintf:");
    myPrintf("%x %o hi %o %x %d %s %x\n", 0x1234, 0x1234, 56, 34, -89, msg, 12);
}
