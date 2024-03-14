#include <stdio.h>

extern "C" void myPrintf(const char *format, ...) __attribute__ ((format(printf, 1, 2)));

int main()
{
    //unsigned a = 0x1234;

    const char *msg = "man";

    puts("C printf:");
    printf("%x %o hi %d %s %c %d\n", 0x1234, 0x1234, -89, msg, 'x', 0x14);

    puts("myPrintf:");
    myPrintf("%x %o hi %d %s %c %d\n%d %s %x %d%%%c%b\n",
              0x1234, 0x1234, -89, msg, 'x', 0x14, -1, "love", 3802, 100, 33, 30);
}
