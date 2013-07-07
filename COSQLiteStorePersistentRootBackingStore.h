#import <Foundation/Foundation.h>
#import "COItemGraph.h"

@class FMDatabase;
@class COItemGraph;
@class CORevisionInfo;
@class CORevisionID;

/**
 * Database connection for manipulating a persistent root backing store.
 *
 * Not a public class, only intended to be used by COSQLiteStore.
 */
@interface COSQLiteStorePersistentRootBackingStore : NSObject
{
    NSString *path_;
    FMDatabase *db_;
}

/**
 * @param
 *      aPath the pathn of a directory where the backing store
 *      should be opened or created.
 */
- (id)initWithPath: (NSString *)aPath;

- (BOOL)close;

- (BOOL) beginTransaction;
- (BOOL) commit;

- (CORevisionInfo *) revisionForID: (CORevisionID *)aToken;

- (COItemGraph *) itemTreeForRevid: (int64_t)revid;

- (COItemGraph *) itemTreeForRevid: (int64_t)revid restrictToItemUUIDs: (NSSet *)itemSet;

/**
 * baseRevid must be < finalRevid.
 * returns nil if baseRevid or finalRevid are not valid revisions.
 */
- (COItemGraph *) partialItemTreeFromRevid: (int64_t)baseRevid toRevid: (int64_t)finalRevid;

- (COItemGraph *) partialItemTreeFromRevid: (int64_t)baseRevid
                                  toRevid: (int64_t)revid
                      restrictToItemUUIDs: (NSSet *)itemSet;

/**
 * 
 * @returns 0 for the first commit on an empty backing store
 */
- (int64_t) writeItemTree: (COItemGraph *)anItemTree
             withMetadata: (NSDictionary *)metadata
               withParent: (int64_t)aParent
            modifiedItems: (NSArray*)modifiedItems; // array of COUUID

- (NSIndexSet *) revidsFromRevid: (int64_t)baseRevid toRevid: (int64_t)finalRevid;

/**
 * Unconditionally deletes the specified revisions
 */
- (BOOL) deleteRevids: (NSIndexSet *)revids;

- (NSIndexSet *) revidsUsedRange;

@end
