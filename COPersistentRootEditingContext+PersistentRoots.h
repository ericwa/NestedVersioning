#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"
#import "COSubtree.h"

@interface COPersistentRootEditingContext (PersistentRoots)

- (COSubtree *)createPersistentRootWithRootItem: (COSubtree *)anItem
									displayName: (NSString *)aName;

- (void) undo: (COSubtree*)aRootOrBranch;
- (void) redo: (COSubtree*)aRootOrBranch;

- (void) undoPersistentRoot: (COSubtree*)aRoot;
- (void) redoPersistentRoot: (COSubtree*)aRoot;

- (void) undoBranch: (COSubtree*)aBranch;
- (void) redoBranch: (COSubtree*)aBranch;

@end
