#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COItem.h"
#import "COPersistentRootEditQueue.h"
#import "COSubtree.h"

@class COStore;

@interface COBranchEditQueue : NSObject
{
	COPersistentRootEditQueue *persistentRoot_; // weak
    COUUID *branch_;

    COPersistentRootStateToken *baseStateToken_;
    
	// -- in-memory mutable state:

	COSubtree *backupTree_;
	COSubtree *tree_;
    
    BOOL isDirty_;
}

- (COPersistentRootEditQueue *) persistentRoot;
- (COUUID *) UUID;



- (NSArray *) stateTokens;

- (COPersistentRootStateToken *)currentState;

- (void) setCurrentState: (COPersistentRootStateToken *)aState;

/** @taskunit manipulation */

- (BOOL) commitChanges;
- (void) discardChanges;

- (COSubtree *)persistentRootTree;
- (void) setPersistentRootTree: (COSubtree *)aSubtree;

@end
