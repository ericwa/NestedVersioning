#import <Foundation/Foundation.h>

@class COUUID;

/**
 * _Store-global_ identifier for a COPersistentRootState.
 * It should be regarded as opaque, and only the store knows how to interpret it.
 *
 * 
 * Could be:
 *  - int64_t (store-global)
 *  - uuid (universally unique)
 *  - hash of contents (universally unique, guarantees data consistency)
 *
 * In any case, the object weights a few tens of bytes at most.
 */
@interface COPersistentRootStateToken : NSObject <NSCopying>
{
    COUUID *prootCache;
    int64_t index;
}

- (id) initWithProotCache: (COUUID *)aUUID
                    index: (int64_t)anIndex;

- (COUUID *) _prootCache;
- (int64_t) _index;

- (id) plist;
+ (COPersistentRootStateToken *) tokenWithPlist: (id)plist;

@end
