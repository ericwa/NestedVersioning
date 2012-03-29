#import "COSubtreeFactory.h"
#import "COStore.h"

extern NSString *kCOType;
extern NSString *kCOName;
extern NSString *kCOContents;
extern NSString *kCOCurrentBranch;
extern NSString *kCOCurrentVersion;
extern NSString *kCOHead;
extern NSString *kCOTail;

extern NSString *kCOTypePersistentRoot;
extern NSString *kCOTypeBranch;

/**
 * This is a set of methods for manipulating the items
 * in an item tree representing persistent roots.
 *
 * This is, deliberately, completely non-object-oriented,
 * since it is just manipulating data.
 */
@interface COSubtreeFactory (PersistentRoots)

/**
 * This should be called before calling the other persistent root
 * methods, which will throw an exception if the persistent
 * root isn't valid.
 */
- (BOOL) isValidPersistentRoot: (COSubtree *)aRoot;
- (BOOL) isValidBranch: (COSubtree *)aRoot;

- (COSubtree *)persistentRootWithInitialVersion: (COUUID *)aVersion
									displayName: (NSString *)aName;

- (NSSet *) branchesOfPersistentRoot: (COSubtree *)aRoot;
- (NSSet *) brancheUUIDsOfPersistentRoot: (COSubtree *)aRoot;

- (COSubtree *) currentBranch: (COSubtree *)aRootOrBranch;

- (COSubtree *) currentBranchOfPersistentRoot: (COSubtree *)aRoot;

- (void) setCurrentBranch: (COSubtree *)aBranch
		forPersistentRoot: (COSubtree *)aRoot;

- (COUUID *) currentVersionForBranch: (COSubtree *)aBranch;

- (COUUID *) currentVersionForBranchOrPersistentRoot: (COSubtree *)aRootOrBranch;

/**
 * Tries to "intelligently" reset the undo/redo limits based on the current
 * limits.
 */
- (void) setCurrentVersion: (COUUID*)aVersion
 forBranchOrPersistentRoot: (COSubtree *)aRootOrBranch
					 store: (COStore *)aStore;

- (COUUID *) headForBranch: (COSubtree*)aBranch;
- (COUUID *) tailForBranch: (COSubtree*)aBranch;

- (void) setCurrentVersion: (COUUID*)aVersion
				 forBranch: (COSubtree*)aBranch
		   updateRedoLimit: (BOOL)setRedoLimit
		   updateUndoLimit: (BOOL)setUndoLimit;

- (BOOL) isBranch: (COSubtree *)anEmbeddedObject;

- (BOOL) isPersistentRoot: (COSubtree *)anEmbeddedObject;

- (COSubtree *)persistentRootByCopyingBranch: (COSubtree *)aBranch;

- (COSubtree *) createBranchOfPersistentRoot: (COSubtree *)aRoot;

- (COSubtree *)createPersistentRootWithRootItem: (COSubtree *)anItem
									displayName: (NSString *)aName
										  store: (COStore *)aStore;

- (NSString *) displayNameForBranchOrPersistentRoot: (COSubtree *)aRootOrBranch;

/**
 * Searches the receiver for embedded objects that are persistent roots.
 * Returns them as COSubtree instances in an NSSet.
 */
- (NSSet *) allEmbeddedPersistentRootsInSubtree: (COSubtree *)aTree;

- (NSSet *) allEmbeddedPersistentRootUUIDsInSubtree: (COSubtree *)aTree;

@end
