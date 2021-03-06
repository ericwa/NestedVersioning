#import <Cocoa/Cocoa.h>

#import <NestedVersioning/COPersistentRootState.h>
#import <NestedVersioning/COStore.h>

#import "EWUndoManager.h"

@interface EWDocument : NSDocument
{
    EWUndoManager *undoManager_;
    COStore *store_;
    COPersistentRootInfo *persistentRoot_;
    
    ETUUID *editingBranch_;
}


- (IBAction) branch: (id)sender;
- (IBAction) showBranches: (id)sender;
- (IBAction) history: (id)sender;
- (IBAction) pickboard: (id)sender;

- (void) recordNewState: (COSubtree*)aState;

- (COPersistentRootInfo *) currentPersistentRoot;
- (COStore *) store;

- (ETUUID *) editingBranch;

/**
 * @param aToken
 *   should be a state token that belongs to [self editingBranch]
 */
- (void) loadStateToken: (CORevisionID *)aToken;

/**
 * @param aToken
 *   should be a state token that belongs to [self editingBranch]
 */
- (void) persistentSwitchToStateToken: (CORevisionID *)aToken;

- (void) switchToBranch: (ETUUID *)aBranchUUID;

- (void) deleteBranch: (ETUUID *)aBranchUUID;

@end
