#import <Foundation/Foundation.h>

typedef struct {
    unsigned char *data;
    size_t length;
    size_t allocated_length;
} co_buffer_t;

void
co_buffer_init(co_buffer_t *buf);

void
co_buffer_free(co_buffer_t *buf);

void
co_buffer_store_integer(co_buffer_t *buf, int64_t value);

void
co_buffer_store_double(co_buffer_t *buf, double value);

void
co_buffer_store_string(co_buffer_t *buf, NSString *value);

void
co_buffer_store_bytes(co_buffer_t *dest, const char *bytes, size_t length);

void
co_buffer_begin_object(co_buffer_t *buf);

void
co_buffer_end_object(co_buffer_t *buf);

void
co_buffer_begin_array(co_buffer_t *buf);

void
co_buffer_end_array(co_buffer_t *buf);
