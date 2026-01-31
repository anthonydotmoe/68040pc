#pragma once
#include <unistd.h>
#include <stddef.h>

/* Stream definitions. Abstraction of ways to access a file. */

typedef struct _stream_module_t {
    /* data supplied by the module */
    char *name;
    long maxbuf;

    /* methods */
    int (*open)(const char *name);
    long (*fillbuf)(void *buf);

    int (*skip)(long cnt);

    int (*close)(void);
    long (*filesize)(void);

    /* data maintained by general streams layer */
    char *buf;
    char *bufp;
    long buf_cnt;
    long fpos;
    int eof;
    long last_shown;

    /* links to neighbor modules */
    struct _stream_module_t *down, *up;
} MODULE;

/* initializer for fields in MODULE not supplied by module */
#define MOD_REST_INIT                                \
    NULL, NULL, 0, 0, 0, 0, /* buffer data */        \
    NULL, NULL              /* down, up pointers */  \

extern MODULE *currmod;

/* Prototypes */

void stream_init(void);
void stream_push(MODULE *mod);
int sopen(const char *name);
long sfilesize(void);
long sread(void *buf, long cnt);
int sseek(long offset, int whence);
int sclose(void);


typedef struct _fs_module_t {
    char *name;

    int (*open)(const char* name);
    ssize_t (*read)(void* buf, size_t count);
    off_t (*seek)(off_t offset, int whence);
    int (*close)(void);
} FS_MODULE;
