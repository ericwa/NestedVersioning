#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "CORevisionID.h"
#import "COSQLiteStore.h"


@class COBranch;
@class COStore;
@class COEditingContext;

@interface COPersistentRootController : NSObject
{
    COSQLiteStore *store_;
    COPersistentRootState *savedState_;
    COEditingContext *editingContext_;
}

- (id) initWithStore: (COSQLiteStore *)aStore
  persistentRootUUID: (COUUID *)aUUID;

- (COUUID *) UUID;

// FIXME: Shouldn't give mutable access
- (COPersistentRootState *) state;

- (COUUID *) editingBranchUUID;
/**
 * Commits on change
 */
- (void) setEditingBranchUUID: (COUUID*)aBranch;

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) resetToRevisionID: (CORevisionID *)aState;

- (void) resetToRevisionIDNoCommit: (CORevisionID *)aState;

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata;
- (void) discardChanges;
- (BOOL) hasChanges;

- (COEditingContext *) editingContext;

@end
