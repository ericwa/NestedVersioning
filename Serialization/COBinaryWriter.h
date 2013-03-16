#import <Foundation/Foundation.h>
@class COUUID;

@interface COBinaryWriter : NSObject
{
    NSMutableData *dest;
}

- (id) initWithMutableData: (NSMutableData*)aDest;

- (void) storeInt64: (int64_t)value;
- (void) storeDouble: (double)aDouble;
- (void) storeUUID: (COUUID *)aUUID;
- (void) storeString: (NSString *)aString;
- (void) storeData: (NSData *)aData;
- (void) beginObject;
- (void) endObject;
- (void) beginArray;
- (void) endArray;

@end
