#include <string.h>

extern int busymain_xetex(int argc, char* argv[]);
extern int busymain_dvipdfmx(int argc, char* argv[]);

int main(int argc, char* argv[])
{
    if(strcmp("xetex", argv[1]) == 0 || strcmp("xelatex", argv[1]) == 0)
        return busymain_xetex(argc - 1, argv + 1);
    else if(strcmp("dvipdfmx", argv[1]) == 0)
        return busymain_dvipdfmx(argc - 1, argv + 1);
}
