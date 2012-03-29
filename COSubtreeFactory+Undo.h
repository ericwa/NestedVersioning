#import "COSubtreeFactory.h"
#import "COStore.h"
#import "COSubtreeDiff.h"

@interface COSubtreeFactory (Undo)

#pragma mark testing ability to undo/redo

- (BOOL) canUndoBranch: (COSubtree*)aBranch
				 store: (COStore *)aStore;
- (BOOL) canRedoBranch: (COSubtree*)aBranch
				 store: (COStore *)aStore;

#pragma mark helper methods

- (BOOL) shouldSkipVersion: (COUUID*) aCommit
				 forBranch: (COSubtree *) aBranch
					 store: (COStore *) aStore;

#pragma mark primitive methods

- (void) undoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore;
- (void) redoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore;

- (NSString *) undoMessageForBranch: (COSubtree*)aBranch
							  store: (COStore *)aStore;
- (NSString *) redoMessageForBranch: (COSubtree*)aBranch
							  store: (COStore *)aStore;

#pragma mark selective undo

/**
 * Returns a diff which can be applied to the contents of 'target',
 * or returns nil if the selective undo is impossible or
 * there is nothing to undo.
 */
- (COSubtreeDiff *) selectiveUndoCommit: (COUUID *) commitToUndo
							  forCommit: (COUUID*) target
								  store: (COStore *)aStore;

/**
 * Returns a diff which can be applied to the contents of 'target'
 */
- (COSubtreeDiff *) selectiveApplyCommit: (COUUID *) commitToDo
							   forCommit: (COUUID*) target
								   store: (COStore *)aStore;

@end
