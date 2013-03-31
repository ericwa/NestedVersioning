#import <Foundation/Foundation.h>

typedef struct {
    void (*co_read_int64)(void*, int64_t);
    void (*co_read_double)(void*, double);
    void (*co_read_string)(void*, NSString *);
    void (*co_read_bytes)(void*, const unsigned char *, size_t);
    void (*co_read_begin_object)(void*);
    void (*co_read_end_object)(void*);
    void (*co_read_begin_array)(void*);
    void (*co_read_end_array)(void*);
} co_reader_callback_t;

void co_reader_read(const unsigned char *bytes, size_t length, void *context, co_reader_callback_t callbacks);
