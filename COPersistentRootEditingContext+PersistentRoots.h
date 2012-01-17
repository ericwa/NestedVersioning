#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"
#import "COItemTreeNode.h"

@interface COPersistentRootEditingContext (PersistentRoots)

/**
 * @returns the UUID of the persistent root item in the receiver
 */
- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COItemTreeNode *)anItem // FIXME: take a tree
										  inItemWithUUID: (ETUUID*)aDest;


- (NSSet *) branchesOfPersistentRoot: (ETUUID *)aRoot;
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot;
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aUUID;

- (ETUUID *) currentVersionForBranch: (ETUUID*)aBranch;

- (ETUUID *) currentVersionForBranchOrPersistentRoot: (ETUUID*)aRootOrBranch;

- (void) setCurrentVersion: (ETUUID*)aVersion
			   forBranch: (ETUUID*)aBranch;

- (void) undo: (ETUUID*)aRootOrBranch;
- (void) redo: (ETUUID*)aRootOrBranch;

- (void) undoPersistentRoot: (ETUUID*)aRoot;
- (void) redoPersistentRoot: (ETUUID*)aRoot;

- (void) undoBranch: (ETUUID*)aBranch;
- (void) redoBranch: (ETUUID*)aBranch;


// special method for copying a branch out of a persistent root to create a standalone
// persistent root. see TestBranchesAndCopies.m
- (ETUUID *)createAndInsertNewPersistentRootByCopyingBranch: (ETUUID *)srcBranch
											 inItemWithUUID: (ETUUID *)destContainer;

- (ETUUID *) createBranchOfPersistentRoot: (ETUUID *)aRoot;

- (BOOL) isBranch: (ETUUID*)anEmbeddedObject;
- (BOOL) isPersistentRoot: (ETUUID*)anEmbeddedObject;


@end
