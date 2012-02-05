#import "COItemFactory.h"

@interface COItemFactory (PersistentRoots)

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
				 forBranch: (COSubtree*)aBranch;

- (BOOL) isBranch: (COSubtree *)anEmbeddedObject;

- (BOOL) isPersistentRoot: (COSubtree *)anEmbeddedObject;

- (COSubtree *)persistentRootByCopyingBranch: (COSubtree *)aBranch;

- (COSubtree *) createBranchOfPersistentRoot: (COSubtree *)aRoot;



@end
