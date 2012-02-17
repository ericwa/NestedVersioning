#import "COSubtreeFactory.h"
#import "COStore.h"

@interface COSubtreeFactory (Undo)

#pragma mark convenience methods

- (void) undo: (COSubtree*)aRootOrBranch
		store: (COStore *)aStore;
- (void) redo: (COSubtree*)aRootOrBranch
		store: (COStore *)aStore;

- (void) undoPersistentRoot: (COSubtree*)aRoot
					  store: (COStore *)aStore;
- (void) redoPersistentRoot: (COSubtree*)aRoot
					  store: (COStore *)aStore;

#pragma mark helper methods

- (BOOL) shouldSkipVersion: (ETUUID*) aCommit
				 forBranch: (COSubtree *) aBranch
					 store: (COStore *) aStore;

#pragma mark primitive methods

- (void) undoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore;
- (void) redoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore;

@end
