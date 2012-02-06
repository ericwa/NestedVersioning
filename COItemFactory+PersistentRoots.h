#import "COItemFactory.h"

@interface COItemFactory (PersistentRoots)

/**
 * This should be called before calling the other persistent root
 * methods, which will throw an exception if the persistent
 * root isn't valid.
 */
- (BOOL) isValidPersistentRoot: (COSubtree *)aRoot;
- (BOOL) isValidBranch: (COSubtree *)aRoot;

- (COSubtree *)persistentRootWithInitialVersion: (ETUUID *)aVersion
									displayName: (NSString *)aName;

- (NSSet *) branchesOfPersistentRoot: (COSubtree *)aRoot;

- (COSubtree *) currentBranchOfPersistentRoot: (COSubtree *)aRoot;

- (void) setCurrentBranch: (COSubtree *)aBranch
		forPersistentRoot: (COSubtree *)aRoot;

- (ETUUID *) currentVersionForBranch: (COSubtree *)aBranch;

- (ETUUID *) currentVersionForBranchOrPersistentRoot: (COSubtree *)aRootOrBranch;

- (ETUUID *) headForBranch: (COSubtree*)aBranch;
- (ETUUID *) tailForBranch: (COSubtree*)aBranch;

- (void) setCurrentVersion: (ETUUID*)aVersion
				 forBranch: (COSubtree*)aBranch
		   updateRedoLimit: (BOOL)setRedoLimit
		   updateUndoLimit: (BOOL)setUndoLimit;

- (BOOL) isBranch: (COSubtree *)anEmbeddedObject;

- (BOOL) isPersistentRoot: (COSubtree *)anEmbeddedObject;

- (COSubtree *)persistentRootByCopyingBranch: (COSubtree *)aBranch;

- (COSubtree *) createBranchOfPersistentRoot: (COSubtree *)aRoot;



@end
