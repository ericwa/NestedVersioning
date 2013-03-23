#import "COBinaryWriter.h"
#import "COMacros.h"

#define CO_BUFFER_INITIAL_LENGTH 4096

void
co_buffer_init(co_buffer_t *dest)
{
    dest->allocated_length = CO_BUFFER_INITIAL_LENGTH;
    dest->data = malloc(CO_BUFFER_INITIAL_LENGTH);
    dest->length = 0;
}

void
co_buffer_free(co_buffer_t *dest)
{
    free(dest->data);
}


static inline void
co_buffer_write(co_buffer_t *dest, const char *data, size_t len)
{
    const size_t currlength = dest->length;
    if (currlength + len > dest->allocated_length)
    {
        dest->allocated_length = currlength + len + CO_BUFFER_INITIAL_LENGTH;
        dest->data = realloc(dest->data, dest->allocated_length);
    }
    
    memcpy(dest->data + currlength, data, len);
    dest->length += len;
}

#define WRITE(v) co_buffer_write(dest, (const char *)&v, sizeof(v))
#define WRTITE_TYPE(t) co_buffer_write(dest, t, 1)

static inline void
co_buffer_store_uint8(co_buffer_t *dest, uint8_t value)
{
    WRITE(value);
}

static inline void
co_buffer_store_uint16(co_buffer_t *dest, uint16_t value)
{
    uint16_t swapped = CFSwapInt16HostToBig(value);
    WRITE(swapped);
}

static inline void
co_buffer_store_uint32(co_buffer_t *dest, uint32_t value)
{
    uint32_t swapped = CFSwapInt32HostToBig(value);
    WRITE(swapped);
}
     
static inline void
co_buffer_store_uint64(co_buffer_t *dest, uint64_t value)
{
    uint64_t swapped = CFSwapInt64HostToBig(value);
    WRITE(swapped);
}

void
co_buffer_store_integer(co_buffer_t *dest, int64_t value)
{
    if (value <= INT8_MAX && value >= INT8_MIN)
    {
        WRTITE_TYPE("B");
        co_buffer_store_uint8(dest, (uint8_t)value);
    }
    else if (value <= INT16_MAX && value >= INT16_MIN)
    {
        WRTITE_TYPE("i");
        co_buffer_store_uint16(dest, (uint16_t)value);
    }
    else if (value <= INT32_MAX && value >= INT32_MIN)
    {
        WRTITE_TYPE("I");
        co_buffer_store_uint32(dest, (uint32_t)value);
    }
    else
    {
        WRTITE_TYPE("L");
        co_buffer_store_uint64(dest, (uint64_t)value);
    }
}

void
co_buffer_store_double(co_buffer_t *dest, double value)
{
	NSSwappedDouble swapped = NSSwapHostDoubleToBig(value);
	WRTITE_TYPE("F");
    WRITE(swapped);
}

void
co_buffer_store_string(co_buffer_t *dest, NSString *value)
{
    const char *utf8String = [value UTF8String];
    const size_t length = strlen(utf8String);
 
    if (length <= UINT8_MAX)
    {
        WRTITE_TYPE("s");
        co_buffer_store_uint8(dest, (uint8_t)length);
    }
    else if (length <= UINT32_MAX)
    {
        WRTITE_TYPE("S");
        co_buffer_store_uint32(dest, (uint32_t)length);
    }
    else
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"Strings longer than 2^32-1 not supported."];
    }

    co_buffer_write(dest, utf8String, length);
}

void
co_buffer_store_bytes(co_buffer_t *dest, const char *bytes, size_t length)
{
    if (length <= UINT8_MAX)
    {
        WRTITE_TYPE("d");
        co_buffer_store_uint8(dest, (uint8_t)length);        
    }
    else if (length <= UINT32_MAX)
    {
        WRTITE_TYPE("D");
        co_buffer_store_uint32(dest, (uint32_t)length);
    }
    else
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"Data longer than 2^32-1 not supported."];
    }
    
    co_buffer_write(dest, bytes, length);
}

void
co_buffer_begin_object(co_buffer_t *dest)
{
    WRTITE_TYPE("{");
}

void
co_buffer_end_object(co_buffer_t *dest)
{
    WRTITE_TYPE("}");
}

void
co_buffer_begin_array(co_buffer_t *dest)
{
    WRTITE_TYPE("[");
}

void
co_buffer_end_array(co_buffer_t *dest)
{
    WRTITE_TYPE("]");
}
