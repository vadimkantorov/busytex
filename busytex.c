#include <string.h>
#include <assert.h>
#include <stdio.h>

extern int busymain_xetex(int argc, char* argv[]);
extern int busymain_dvipdfmx(int argc, char* argv[]);

int main(int argc, char* argv[])
{
    if(strcmp("xetex", argv[1]) == 0 || strcmp("xelatex", argv[1]) == 0)
    {
        printf("Bye world!\n");
        argv[1] = argv[0];
        return busymain_xetex(argc - 1, argv + 1);
    }
    else if(strcmp("dvipdfmx", argv[1]) == 0)
    {
        argv[1] = argv[0];
        return busymain_dvipdfmx(argc - 1, argv + 1);
    }
    /*else if(strcmp("latexmk", argv[1]) == 0)
    {
        argv[1] = argv[0];
        int ret = busymain_xetex(argc - 1, argv + 1);
        if(ret != 0)
            return ret;

        char* source_path = argv[argc - 1];
        for(int i = 1; i < argc; i++)
        {
            if(argv[i][0] != '-')
            {
                source_path = argv[i];
                break;
            }
        }
        int source_path_len = strlen(source_path);
        char* ext = source_path + source_path_len - 4;
        assert(source_path_len >= 4 && strcmp(".tex", ext) == 0);
        strcpy(ext, ".xdv");
        argv[2] = source_path;
        return busymain_dvipdfmx(2, argv + 1);
    }*/
}
