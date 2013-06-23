#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "CORevisionID.h"
#import "COSQLiteStore.h"
#import "COPersistentRootState.h"

@class COBranch;
@class COStore;
@class COEditingContext;

/**
 * goals:
 *  - intended to be the model object backing a document window UI.
 *
 * - support having an object's branches open in their own
 *   windows an editing them simiultaneously
 *
 */
@interface COPersistentRoot : NSObject
{
    COStore *rootStore_; // weak
    COPersistentRootState *savedState_;
    COEditingContext *editingContext_;
}

- (COUUID *) UUID;

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
