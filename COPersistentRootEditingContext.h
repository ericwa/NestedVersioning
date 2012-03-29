#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COItem.h"
#import "COStore.h"
#import "COSubtree.h"

@class COStore;

/**
 * COPersistentRootEditingContext is the heart of NestedVersioning; it supports
 * creating a tree of COSubtree objects representing the contents of a commit on disk,
 * and allows the user to edit that tree, and commit the edited version to disk.
 *
 * It also implements the support for nested persistent roots. The "path" ivar
 * is what allows that.
 *
 * For example, if an editing context was created for 
 * the path "<photo library uuid>/<photo 1>", the path is used both
 * when creating the context, to look up the current version of the
 * photo library, and then look up the current version of "photo 1"
 * inside the current photo library.
 *
 * each UUID the path is the UUID of an item which should have
 * "type" = "persistentRoot" or "type" = "branch". the first UUID 
 * must be an item in the store's root tree, the second one is in the item tree
 * inside the commit which the first persistent root refers to, etc.
 * 
 * the path is also used when making a commit because each persistent
 * root in the path needs to be updated.
 */
@interface COPersistentRootEditingContext : NSObject <NSCopying>
{
	COStore *store;
	
	COPath *path;
	
	/**
	 * this is the commit we load our data from.
	 * when we make a commit, the parent of the commit will be set to this.
	 *
	 * if the branch we are editing has been changed from this value,
	 * we will need to do a merge
	 */
	COUUID *baseCommit;
		
	// -- in-memory mutable state:
	
	COSubtree *tree;
}

/** @taskunit creation */

+ (COPersistentRootEditingContext *) editingContextForEditingPath: (COPath*)aPath
														  inStore: (COStore *)aStore;

/**
 * preconditions: (if not satisfied, the method should throw an exception)
 *  - the provided UUID must identify a valid persistent root item in the
 *    reciever, which has a valid branch child, which point to an (existing) store commit/version.
 *    These must be committed already, not just in-memory.
 *  
 *  - one corner case is where the persistent root exists, but in-memory it is switched
 *    to a different (new) branch. However this method completely ignore the receiver context;
 *    the only information it uses in the receiver is [self path].
 */
- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (COSubtree *)aRoot;

/**
 * same preconditions as above
 */
- (COPersistentRootEditingContext *) editingContextForEditingBranchOfPersistentRoot: (COSubtree *)aBranch;

/**
 * private method; public users should use -[COStore rootContext].
 */
+ (COPersistentRootEditingContext *) editingContextForEditingTopLevelOfStore: (COStore *)aStore;

/**
 * returns an independent copy.
 * FIXME: would it be useful to have a copy without any local changes?
 */
- (id)copyWithZone:(NSZone *)zone;

- (COPath *) path;
- (COStore *) store;



/**
 * preconditions: (if not satisfied, the method should throw an exception)
 * 
 * - given the context has a path "u1/u2/u3../uN", 
 *   * path element u1 must be a persistent root in the store's top-level persistent root.
 *   * for each path element uI in the range u1..uN, the persistent root item uI must
 *     have a current branch child item which points to a version which represents 
 *     the contents of that persistent root.
 *
 */
- (COUUID *) commitWithMetadata: (COSubtree *)theMetadata;

/**
 * access the mutable tree, through which users can modify the current state of the persistent root
 */
- (COSubtree *)persistentRootTree;

- (void) setPersistentRootTree: (COSubtree *)aSubtree;

- (COUUID *) baseCommit;

@end
