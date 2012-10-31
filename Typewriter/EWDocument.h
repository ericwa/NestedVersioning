#import <Cocoa/Cocoa.h>

#import <NestedVersioning/COPersistentRoot.h>
#import <NestedVersioning/COStore.h>

#import "EWUndoManager.h"

@interface EWDocument : NSDocument
{
    EWUndoManager *undoManager_;
    COStore *store_;
    COPersistentRoot *persistentRoot_;
    
    COUUID *editingBranch_;
}


- (IBAction) branch: (id)sender;
- (IBAction) showBranches: (id)sender;
- (IBAction) history: (id)sender;
- (IBAction) pickboard: (id)sender;

- (void) recordNewState: (COSubtree*)aState;

- (COPersistentRoot *) currentPersistentRoot;

- (COUUID *) editingBranch;

/**
 * @param aToken
 *   should be a state token that belongs to [self editingBranch]
 */
- (void) loadStateToken: (COPersistentRootStateToken *)aToken;

/**
 * @param aToken
 *   should be a state token that belongs to [self editingBranch]
 */
- (void) persistentSwitchToStateToken: (COPersistentRootStateToken *)aToken;

- (void) switchToBranch: (COUUID *)aBranchUUID;

- (void) deleteBranch: (COUUID *)aBranchUUID;

@end
