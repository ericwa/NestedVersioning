#import <Foundation/Foundation.h>

#import <EtoileFoundation/ETUUID.h>
#import "CORevisionID.h"
#import "COSQLiteStore.h"


@class COBranch;
@class COStore;
@class COObjectGraphContext;

@interface COPersistentRootController : NSObject
{
    COSQLiteStore *store_;
    COPersistentRootInfo *savedState_;
    COObjectGraphContext *editingContext_;
}

- (id) initWithStore: (COSQLiteStore *)aStore
  persistentRootUUID: (ETUUID *)aUUID;

- (ETUUID *) UUID;

// FIXME: Shouldn't give mutable access
- (COPersistentRootInfo *) state;

- (ETUUID *) editingBranchUUID;
/**
 * Commits on change
 */
- (void) setEditingBranchUUID: (ETUUID*)aBranch;

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) resetToRevisionID: (CORevisionID *)aState;

- (void) resetToRevisionIDNoCommit: (CORevisionID *)aState;

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata;
- (void) discardChanges;
- (BOOL) hasChanges;

- (COObjectGraphContext *) editingContext;

@end
