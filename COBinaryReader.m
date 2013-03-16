#import "COBinaryReader.h"
#import "COUUID.h"

@implementation COBinaryReader

static inline uint8_t readUint8(const unsigned char *bytes)
{
    return *bytes;
}

static inline uint16_t readUint16(const unsigned char *bytes)
{
    uint16_t unswapped;
    memcpy(&unswapped, bytes, 2);
    return CFSwapInt16BigToHost(unswapped);
}

static inline uint32_t readUint32(const unsigned char *bytes)
{
    uint32_t unswapped;
    memcpy(&unswapped, bytes, 4);
    return CFSwapInt32BigToHost(unswapped);
}

static inline uint64_t readUint64(const unsigned char *bytes)
{
    uint64_t unswapped;
    memcpy(&unswapped, bytes, 8);
    return CFSwapInt64BigToHost(unswapped);
}

- (void) readData: (NSData*)aData
     withDelegate: (id<COBinaryReaderDelegate>)aDelegate
{
    data_ = aData;
    delegate_ = aDelegate;
    bytes_ = [aData bytes];
    length_ = [aData length];
    
    while ([self canReadValue])
    {
        [self readValue];
    }
}

- (BOOL) canReadValue
{
    return pos_ < length_;
}

- (void) readValue
{
    NSAssert(pos_ >= length_, @"Read beyond end of data");

    const char type = bytes_[pos_];
    pos_++;
    
    switch (type)
    {
        case 'B':
            [delegate_ readInt64: (int64_t)readUint8(bytes_ + pos_)];
            pos_++;
            break;
        case 'i':
            [delegate_ readInt64: (int64_t)readUint16(bytes_ + pos_)];
            pos_ += 2;
            break;
        case 'I':
            [delegate_ readInt64: (int64_t)readUint32(bytes_ + pos_)];
            pos_ += 4;
            break;
        case 'L':
            [delegate_ readInt64: (int64_t)readUint64(bytes_ + pos_)];
            pos_ += 8;
            break;
        case '@':
        {
            COUUID *uuid = [[COUUID alloc] initWithBytes: &bytes_[pos_]];
            [delegate_ readUUID: uuid];
            [uuid release];
            pos_ += 16;
            break;
        }
        case 's':
        {
            uint8_t dataLen = readUint8(&bytes_[pos_]);
            pos_++;
            
            NSString *str = [[NSString alloc] initWithBytes: bytes_ + pos_
                                                     length: dataLen
                                                   encoding: NSUTF8StringEncoding];
            [delegate_ readString: str];
            [str release];
            pos_ += dataLen;
            break;
        }
        case 'S':
        {
            uint32_t dataLen = readUint32(&bytes_[pos_]);
            pos_ += 4;

            NSString *str = [[NSString alloc] initWithBytes: bytes_ + pos_
                                                     length: dataLen
                                                   encoding: NSUTF8StringEncoding];
            [delegate_ readString: str];
            [str release];
            pos_ += dataLen;
            break;
        }
        case 'd':
        {
            uint8_t dataLen = readUint8(&bytes_[pos_]);
            pos_++;
            [delegate_ readData: [data_ subdataWithRange: NSMakeRange(pos_, dataLen)]];
            pos_ += dataLen;
            break;
        }
        case 'D':
        {
            uint32_t dataLen = readUint32(&bytes_[pos_]);
            pos_ += 4;
            [delegate_ readData: [data_ subdataWithRange: NSMakeRange(pos_, dataLen)]];
            pos_ += dataLen;
            break;
        }
        case '{':
            [delegate_ beginObject];
            break;
        case '}':
            [delegate_ endObject];
            break;
        case '[':
            [delegate_ beginArray];
            break;
        case ']':
            [delegate_ endArray];            
            break;
        default:
            [NSException raise: NSGenericException
                        format: @"unknown type '%c'", type];
    }
}

@end
