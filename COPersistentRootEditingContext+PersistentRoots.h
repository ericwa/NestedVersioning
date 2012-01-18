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
// FIXME: Not sure what should happen to the undo/redo limits. For now we'll reset them
// so the new persistent root has no undo/redo history.
- (ETUUID *)createAndInsertNewPersistentRootByCopyingBranch: (ETUUID *)srcBranch
										   ofPersistentRoot: (ETUUID *)srcPersistentRoot
											 inItemWithUUID: (ETUUID *)destContainer;

- (ETUUID *) createBranchOfPersistentRoot: (ETUUID *)aRoot;

- (BOOL) isBranch: (ETUUID*)anEmbeddedObject;
- (BOOL) isPersistentRoot: (ETUUID*)anEmbeddedObject;


@end
