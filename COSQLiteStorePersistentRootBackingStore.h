#import <Foundation/Foundation.h>
#import "COItemTree.h"

@class FMDatabase;
@class COItemTree;

/**
 * Database connection for manipulating a persistent root backing store.
 *
 * Not a public class.
 *
 * Note that this class is 
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

- (NSDictionary *) metadataForRevid: (int64_t)revid;

- (int64_t) parentForRevid: (int64_t)revid;

- (COItemTree *) itemTreeForRevid: (int64_t)revid;

/**
 * baseRevid must be < finalRevid.
 * returns nil if baseRevid or finalRevid are not valid revisions.
 */
- (COItemTree *) partialItemTreeFromRevid: (int64_t)baseRevid toRevid: (int64_t)finalRevid;

/**
 * 
 * @returns 0 for the first commit on an empty backing store
 */
- (int64_t) writeItemTree: (COItemTree *)anItemTree
             withMetadata: (NSDictionary *)metadata
               withParent: (int64_t)aParent
            modifiedItems: (NSArray*)modifiedItems; // array of COUUID

- (NSIndexSet *) revidsFromRevid: (int64_t)baseRevid toRevid: (int64_t)finalRevid;

- (BOOL) deleteRevids: (NSIndexSet *)revids;

@end
