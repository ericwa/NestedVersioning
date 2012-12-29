#import "COPersistentRoot.h"
#import "COBranch.h"
#import "COStore.h"
#import "COSQLiteStore.h"

@interface COPersistentRoot (Private)

- (COSQLiteStore *) store;

- (id)initWithStoreEditQueue: (COStore *)aRootStore persistentRoot: (COPersistentRootPlist *)metadata;

- (COPersistentRootPlist *) savedState;

@end

@interface COBranch (Private)

- (id)initWithPersistentRoot: (COPersistentRoot*)aRoot
                      branch: (COUUID*)aBranch
          trackCurrentBranch: (BOOL)track;

/**
 * the branch of the special "current branch" edit queue
 * can change.
 */
- (void) setBranch: (COUUID *)aBranch;

@end

@interface COStore (Private)

- (COSQLiteStore *)store;

@end