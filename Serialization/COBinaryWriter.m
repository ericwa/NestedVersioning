#import "COBinaryWriter.h"
#import "COMacros.h"
#import "COUUID.h"

@implementation COBinaryWriter

- (id) initWithMutableData: (NSMutableData*)aDest
{
    SUPERINIT;
    ASSIGN(dest, aDest);
    return self;
}

- (void) dealloc
{
    [dest release];
    [super dealloc];
}

#define WRITE_BYTES(b, l) [dest appendBytes: b length: l]
#define WRITE(v) WRITE_BYTES(&v, sizeof(v))

static inline void storeUint8(NSMutableData *dest, uint8_t value)
{
    WRITE(value);
}

static inline void storeUint16(NSMutableData *dest, uint16_t value)
{
    uint16_t swapped = CFSwapInt16HostToBig(value);
    WRITE(swapped);
}

static inline void storeUint32(NSMutableData *dest, uint32_t value)
{
    uint32_t swapped = CFSwapInt32HostToBig(value);
    WRITE(swapped);
}
     
static inline void storeUint64(NSMutableData *dest, uint64_t value)
{
    uint64_t swapped = CFSwapInt64HostToBig(value);
    WRITE(swapped);
}

static inline void storeType(NSMutableData *dest, char value)
{
    [dest appendBytes: &value length: 1];
}

- (void) storeInt64: (int64_t)value
{
    if (value <= INT8_MAX && value >= INT8_MIN)
    {
        storeType(dest, 'B');
        storeUint8(dest, (uint8_t)value);
    }
    else if (value <= INT16_MAX && value >= INT16_MIN)
    {
        storeType(dest, 'i');
        storeUint16(dest, (uint16_t)value);
    }
    else if (value <= INT32_MAX && value >= INT32_MIN)
    {
        storeType(dest, 'I');
        storeUint32(dest, (uint32_t)value);
    }
    else
    {
        storeType(dest, 'L');
        storeUint64(dest, (uint64_t)value);
    }
}

- (void) storeDouble: (double)aDouble
{
	NSSwappedDouble swapped = NSSwapHostDoubleToBig(aDouble);
	storeType(dest, 'F');
    WRITE(swapped);
}

- (void) storeUUID: (COUUID *)aUUID
{
    storeType(dest, '@');
    WRITE_BYTES([aUUID bytes], 16);
}

- (void) storeString: (NSString *)aString
{
    const char *utf8String = [aString UTF8String];
    const size_t length = strlen(utf8String);
 
    if (length <= UINT8_MAX)
    {
        storeType(dest, 's');
        storeUint8(dest, (uint8_t)length);
    }
    else if (length <= UINT32_MAX)
    {
        storeType(dest, 'S');
        storeUint32(dest, (uint32_t)length);
    }
    else
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"Strings longer than 2^32-1 not supported."];
    }

    WRITE_BYTES(utf8String, length);
}

- (void) storeData: (NSData *)aData
{
    const char *bytes = [aData bytes];
    const size_t length = [aData length];
    
    if (length <= UINT8_MAX)
    {
        storeType(dest, 'd');
        storeUint8(dest, (uint8_t)length);        
    }
    else if (length <= UINT32_MAX)
    {
        storeType(dest, 'D');
        storeUint32(dest, (uint32_t)length);
    }
    else
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"Strings longer than 2^32-1 not supported."];
    }
    
    WRITE_BYTES(bytes, length);
}

- (void) beginObject
{
    storeType(dest, '{');
}

- (void) endObject
{
    storeType(dest, '}');
}

- (void) beginArray
{
    storeType(dest, '[');
}

- (void) endArray
{
    storeType(dest, ']');
}

@end
