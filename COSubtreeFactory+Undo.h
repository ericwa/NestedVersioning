#import "COSubtreeFactory.h"
#import "COStore.h"

@interface COSubtreeFactory (Undo)

- (void) undo: (COSubtree*)aRootOrBranch
		store: (COStore *)aStore;
- (void) redo: (COSubtree*)aRootOrBranch
		store: (COStore *)aStore;

- (void) undoPersistentRoot: (COSubtree*)aRoot
					  store: (COStore *)aStore;
- (void) redoPersistentRoot: (COSubtree*)aRoot
					  store: (COStore *)aStore;

- (void) undoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore;
- (void) redoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore;

@end
