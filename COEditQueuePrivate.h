#import "COPersistentRootEditQueue.h"
#import "COBranchEditQueue.h"
#import "COStoreEditQueue.h"
#import "COSQLiteStore.h"

@interface COPersistentRootEditQueue (Private)

- (COSQLiteStore *) store;

- (id)initWithStoreEditQueue: (COStoreEditQueue *)aRootStore persistentRoot: (COPersistentRootPlist *)metadata;

- (COPersistentRootPlist *) savedState;

@end

@interface COBranchEditQueue (Private)

- (id)initWithPersistentRoot: (COPersistentRootEditQueue*)aRoot
                      branch: (COUUID*)aBranch
          trackCurrentBranch: (BOOL)track;

/**
 * the branch of the special "current branch" edit queue
 * can change.
 */
- (void) setBranch: (COUUID *)aBranch;

@end

@interface COStoreEditQueue (Private)

- (COSQLiteStore *)store;

@end