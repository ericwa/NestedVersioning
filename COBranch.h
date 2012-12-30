#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COItem.h"

@class COPersistentRoot;
@class CORevisionID;
@class COEditingContext;

@interface COBranch : NSObject
{
	COPersistentRoot *persistentRoot_; // weak
    COUUID *branch_;
    BOOL isTrackingCurrentBranch_;
    
	// -- in-memory mutable state:

	COEditingContext *editingContext_;
}

- (COPersistentRoot *) persistentRoot;
- (COUUID *) UUID;

- (CORevisionID *) currentRevisionID;
- (CORevisionID *) headRevisionID;
- (CORevisionID *) tailRevisionID;

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) setCurrentRevisionID: (CORevisionID *)aState;

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata;
- (void) discardChanges;
- (BOOL) hasChanges;

- (COEditingContext *) editingContext;

@end
