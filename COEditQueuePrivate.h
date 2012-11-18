#import "COPersistentRootEditQueue.h"
#import "COBranchEditQueue.h"
#import "COStoreEditQueue.h"

@interface COPersistentRootEditQueue (Private)

- (COStoreEditQueue *) storeEditQueue;

- (id)initWithRootStore: (COStoreEditQueue *)aRootStore uuid: (COUUID *)aUUID isNew: (BOOL)isNew;

@end

@interface COBranchEditQueue (Private)

- (id)initWithRoot: (COPersistentRootEditQueue*)aRoot branch: (COUUID*)aBranch initialState: (COPersistentRootStateToken *)aState;

/**
 * the branch of the special "current branch" edit queue
 * can change.
 */
- (void) setBranch: (COUUID *)aBranch;

// FIXME: add delta api
- (COPersistentRootState *) fullState;

@end

@interface COStoreEditQueue (Private)

- (COStore *)store;

@end