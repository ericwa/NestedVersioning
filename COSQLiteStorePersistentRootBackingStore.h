#import <Foundation/Foundation.h>
#import "COItemTree.h"

@class FMDatabase;
@class COPartialItemTree;

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

- (COItemTree *) itemTreeForRevid: (int64_t)revid;

- (COPartialItemTree *) partialItemTreeFromRevid: (int64_t)baseRevid toRevid: (int64_t)finalRevid;

- (int64_t) writeItemTree: (COItemTree *)anItemTree
             withMetadata: (NSDictionary *)metadata
               withParent: (int64_t)aParent
            modifiedItems: (NSArray*)modifiedItems; // array of COUUID

- (void) iteratePartialItemTrees: (void (^)(NSSet *))aBlock;

@end
