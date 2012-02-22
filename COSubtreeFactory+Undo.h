#import "COSubtreeFactory.h"
#import "COStore.h"

@interface COSubtreeFactory (Undo)

#pragma mark testing ability to undo/redo

- (BOOL) canUndo: (COSubtree*)aRootOrBranch
		   store: (COStore *)aStore;
- (BOOL) canRedo: (COSubtree*)aRootOrBranch
		   store: (COStore *)aStore;

- (BOOL) canUndoPersistentRoot: (COSubtree*)aRoot
						 store: (COStore *)aStore;
- (BOOL) canRedoPersistentRoot: (COSubtree*)aRoot
						 store: (COStore *)aStore;

- (BOOL) canUndoBranch: (COSubtree*)aBranch
				 store: (COStore *)aStore;
- (BOOL) canRedoBranch: (COSubtree*)aBranch
				 store: (COStore *)aStore;

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
