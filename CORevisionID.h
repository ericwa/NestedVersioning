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
@interface CORevisionID : NSObject <NSCopying>
{
    COUUID *backingStoreUUID_;
    int64_t revisionIndex_;
}

- (id) initWithPersistentRootBackingStoreUUID: (COUUID *)aUUID
                                revisionIndex: (int64_t)anIndex;

- (COUUID *) backingStoreUUID;
- (int64_t) revisionIndex;
/**
 * Returns a new CORevisionID with the stame backing store UUID but the given revid
 */
- (CORevisionID *) revisionIDWithRevisionIndex: (int64_t)anIndex;

- (id) plist;
+ (CORevisionID *) revisionIDWithPlist: (id)plist;

@end
