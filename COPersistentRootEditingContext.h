#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COItem.h"
#import "COStore.h"
#import "COSubtree.h"

@class COStore;


@interface COPersistentRootEditingContext : NSObject <NSCopying>
{
	COStore *store_;
    
    COPersistentRoot *metadata_;
    COUUID *editingBranch_;

	// -- in-memory mutable state:
	
	COSubtree *tree_;
}

// FIXME: move to COStore?

/** @taskunit creation - new persistent root */

/*
 Note: the first commit will actually create the persistent root.
 TODO: actually implement these
 */

/**
 * creates a new persistent root
 */
+ (COPersistentRootEditingContext *) contextForNewPersistentRootInStore: (COStore *)aStore;

/**
 * creates a new persistent root by copying an existing one
 */
+ (COPersistentRootEditingContext *) contextForCopyingPersistentRootWithUUID: (COUUID *)aUUID
                                                                     inStore: (COStore *)aStore;

/** @taskunit creation - editing existing persistent root */

/**
 * editing current branch of a proot
 */
+ (COPersistentRootEditingContext *) contextForEditingPersistentRootWithUUID: (COUUID *)aUUID
                                                                     inStore: (COStore *)aStore;

/**
 * editing a branch of a proot
 */
+ (COPersistentRootEditingContext *) contextForEditingBranch: (COUUID *)aBranch
                                    ofPersistentRootWithUUID: (COUUID *)aUUID
                                                     inStore: (COStore *)aStore;

/**
 * returns an independent copy.
 * FIXME: would it be useful to have a copy without any local changes?
 */
- (id)copyWithZone:(NSZone *)zone;


/** @taskunit access */

- (COUUID *) UUID;
- (COStore *) store;
/**
 * Don't mutate
 */
- (COPersistentRoot *) persistentRootMetadata;


/** @taskunit manipulation */



- (COPersistentRootStateToken *) commitWithMetadata: (COSubtree *)theMetadata;

/**
 * access the mutable tree, through which users can modify the current state of the persistent root
 */
- (COSubtree *)persistentRootTree;

- (void) setPersistentRootTree: (COSubtree *)aSubtree;

@end
