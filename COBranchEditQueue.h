#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COItem.h"
#import "COSubtree.h"

@class COPersistentRootEditQueue;
@class COStore;
@class CORevisionID;
@class COEditingContext;

@interface COBranchEditQueue : NSObject
{
	COPersistentRootEditQueue *persistentRoot_; // weak
    COUUID *branch_;
    BOOL isTrackingCurrentBranch_;
    
	// -- in-memory mutable state:

	COEditingContext *editingContext_;
}

- (COPersistentRootEditQueue *) persistentRoot;
- (COUUID *) UUID;

- (CORevisionID *)currentState;
- (CORevisionID *)head;
- (CORevisionID *)tail;

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) setCurrentState: (CORevisionID *)aState;

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata;
- (void) discardChanges;

- (COEditingContext *)editingContext;

@end
