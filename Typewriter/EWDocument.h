#import <Cocoa/Cocoa.h>

#import <NestedVersioning/COPersistentRootPlist.h>
#import <NestedVersioning/COStore.h>

#import "EWUndoManager.h"

@interface EWDocument : NSDocument
{
    EWUndoManager *undoManager_;
    COStore *store_;
    COPersistentRootPlist *persistentRoot_;
    
    COUUID *editingBranch_;
}


- (IBAction) branch: (id)sender;
- (IBAction) showBranches: (id)sender;
- (IBAction) history: (id)sender;
- (IBAction) pickboard: (id)sender;

- (void) recordNewState: (COSubtree*)aState;

- (COPersistentRootPlist *) currentPersistentRoot;
- (COStore *) store;

- (COUUID *) editingBranch;

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

- (void) switchToBranch: (COUUID *)aBranchUUID;

- (void) deleteBranch: (COUUID *)aBranchUUID;

@end
