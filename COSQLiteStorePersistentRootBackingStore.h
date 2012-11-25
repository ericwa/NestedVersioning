#import <Foundation/Foundation.h>
#import "COObjectTree.h"

@class FMDatabase;

/**
 * Database connection for manipulating a persistent root backing store.
 */
@interface COSQLiteStorePersistentRootBackingStore : NSObject
{
    FMDatabase *db_;
}

- (id)initWithPath: (NSString *)aPath;

- (NSDictionary *) metadataForRevid: (int64_t)revid;

- (int64_t) parentForRevid: (int64_t)revid;

- (COObjectTree *) itemTreeForRevid: (int64_t)revid;

- (int64_t) writeItemTree: (COObjectTree *)anItemTree
             withMetadata: (NSDictionary *)metadata
               withParent: (int64_t)aParent
            modifiedItems: (NSArray*)modifiedItems; // array of COUUID

@end
