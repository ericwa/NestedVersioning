#import "TestCommon.h"


@interface TestBinaryReadWrite : NSObject <UKTest>
{
}
@end


@implementation TestBinaryReadWrite

static void co_read_int64(void *ctx, int64_t val)
{
    NSLog(@"read int64 '%lld'", (long long int)val);
}
static void co_read_double(void *ctx, double val)
{
    NSLog(@"read double '%lf'", val);
}
static void co_read_string(void *ctx, NSString *val)
{
    NSLog(@"read string '%@'", val);
}
static void co_read_uuid(void *ctx, COUUID *uuid)
{
    NSLog(@"read uuid %@", uuid);
}
static void co_read_bytes(void *ctx, const unsigned char *val, size_t size)
{
    NSLog(@"read bytes '%@'", [NSData dataWithBytes: val length: size]);
}
static void co_read_begin_object(void *ctx)
{
    NSLog(@"begin object");
}
static void co_read_end_object(void *ctx)
{
    NSLog(@"end object");
}
static void co_read_begin_array(void *ctx)
{
    NSLog(@"begin array");
}
static void co_read_end_array(void *ctx)
{
    NSLog(@"end array");
}

- (void)testBasic
{
    COUUID *uuid = [COUUID UUID];
    
    co_buffer_t buf;
    co_buffer_init(&buf);
    co_buffer_begin_object(&buf);
    co_buffer_begin_array(&buf);
    co_buffer_store_integer(&buf, 0);
    co_buffer_store_integer(&buf, -1);
    co_buffer_store_integer(&buf, 1);
    co_buffer_store_integer(&buf, -255);
    co_buffer_store_integer(&buf, 255);
    co_buffer_store_integer(&buf, -256);
    co_buffer_store_integer(&buf, 256);
    co_buffer_store_integer(&buf, -65535);
    co_buffer_store_integer(&buf, 65535);
    co_buffer_store_integer(&buf, -65536);
    co_buffer_store_integer(&buf, 65536);
    co_buffer_store_double(&buf, 3.14159);
    co_buffer_store_string(&buf, @"hello world!");
    co_buffer_store_uuid(&buf, uuid);
    co_buffer_end_array(&buf);
    co_buffer_end_object(&buf);
    
    co_reader_callback_t cb = {
        co_read_int64,
        co_read_double,
        co_read_string,
        co_read_uuid,
        co_read_bytes,
        co_read_begin_object,
        co_read_end_object,
        co_read_begin_array,
        co_read_end_array
    };
    co_reader_read(co_buffer_get_data(&buf),
                   co_buffer_get_length(&buf),
                   NULL,
                   cb);
    
    co_buffer_free(&buf);
}

#define WRITE_ITERATIONS 1000000LL
#define READ_ITERATIONS 1000000LL

static volatile char dest[2048];

- (void) testWritePerf
{
    COUUID *uuid = [COUUID UUID];
    NSDate *startDate = [NSDate date];
    int64_t iter = 0;
    for (int64_t i=0; i<WRITE_ITERATIONS; i++)
    {
        co_buffer_t buf;
        co_buffer_init(&buf);
        co_buffer_begin_object(&buf);
        co_buffer_begin_array(&buf);
        co_buffer_store_integer(&buf, 0);
        co_buffer_store_integer(&buf, -1);
        co_buffer_store_integer(&buf, 1);
        co_buffer_store_integer(&buf, -255);
        co_buffer_store_integer(&buf, 255);
        co_buffer_store_integer(&buf, -256);
        co_buffer_store_integer(&buf, 256);
        co_buffer_store_integer(&buf, -65535);
        co_buffer_store_integer(&buf, 65535);
        co_buffer_store_integer(&buf, -65536);
        co_buffer_store_integer(&buf, 65536);
        co_buffer_store_double(&buf, 3.14159);
        co_buffer_store_string(&buf, @"hello world!");
        co_buffer_store_uuid(&buf, uuid);
        co_buffer_end_array(&buf);
        co_buffer_end_object(&buf);
        
        memcpy(dest, co_buffer_get_data(&buf), co_buffer_get_length(&buf));
        
        co_buffer_free(&buf);
        
        iter++;
    }
    
    NSLog(@"writing %lld iterations of the writing test took %lf ms", iter, 1000.0 * [[NSDate date] timeIntervalSinceDate: startDate]);
}

@end