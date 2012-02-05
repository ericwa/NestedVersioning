#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"
#import "COSubtree.h"

@interface COPersistentRootEditingContext (PersistentRoots)

/**
 * @returns the UUID of the persistent root item in the receiver
 */
- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COSubtree *)anItem
										  inItemWithUUID: (ETUUID*)aDest;

- (BOOL) isBranch: (ETUUID *)anEmbeddedObject;
- (BOOL) isPersistentRoot: (ETUUID *)anEmbeddedObject;

- (void) undo: (ETUUID*)aRootOrBranch;
- (void) redo: (ETUUID*)aRootOrBranch;

- (void) undoPersistentRoot: (ETUUID*)aRoot;
- (void) redoPersistentRoot: (ETUUID*)aRoot;

- (void) undoBranch: (ETUUID*)aBranch;
- (void) redoBranch: (ETUUID*)aBranch;

@end
