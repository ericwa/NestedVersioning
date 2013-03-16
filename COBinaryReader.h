#import <Foundation/Foundation.h>

@class COUUID;

@protocol COBinaryReaderDelegate <NSObject>

- (void) readInt64: (int64_t)value;
- (void) readDouble: (double)aDouble;
- (void) readUUID: (COUUID *)aUUID;
- (void) readString: (NSString *)aString;
- (void) readData: (NSData *)aData;
- (void) beginObject;
- (void) endObject;
- (void) beginArray;
- (void) endArray;

@end


@interface COBinaryReader : NSObject
{
    id<COBinaryReaderDelegate> delegate_;
    NSData *data_;
    const unsigned char *bytes_;
    NSUInteger pos_;
    NSUInteger length_;
}

- (void) readData: (NSData*)aData withDelegate: (id<COBinaryReaderDelegate>)aDelegate;

@end
