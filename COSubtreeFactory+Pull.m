#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "COUUID.h"
#import "COStorePrivate.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtree.h"
#import "COSubtreeDiff.h"

@implementation COSubtreeFactory (Pull)

- (void) pullChangesFromBranch: (COSubtree*)srcBranch
					  toBranch: (COSubtree*)destBranch
						 store: (COStore *)aStore
{
	COUUID *srcCommit = [self currentVersionForBranch: srcBranch];
	COUUID *destCommit = [self currentVersionForBranch: destBranch];
	
	if ([aStore isCommit: destCommit parentOfCommit: srcCommit])
	{
		NSLog(@"pullChangesFromBranch: fast-forward");
		
		[self setCurrentVersion: srcCommit
					  forBranch: destBranch
				updateRedoLimit: YES
				updateUndoLimit: NO];
	}
	else
	{
		NSLog(@"pullChangesFromBranch: need to do full merge.");
		
		COUUID *ancestor = [aStore commonAncestorForCommit: srcCommit
												 andCommit: destCommit];
		
		NSLog(@"common ancestor: %@", ancestor);
		
		/**
		 * now, open up the two branches, and do a merge.
		 *
		 * note that we need a special merge strategy for merging branch objects:
		 * call this method recursively!
		 */
		
		COSubtree *ancestorSubtree = [aStore treeForCommit: ancestor];
		COSubtree *srcCommitSubtree = [aStore treeForCommit: srcCommit];
		COSubtree *destCommitSubtree = [aStore treeForCommit: destCommit];
		
		COSubtreeDiff *diffAncestorToSrc = [COSubtreeDiff diffSubtree: ancestorSubtree
														withSubtree: srcCommitSubtree 
												   sourceIdentifier: @"ancestor-src"];	
		COSubtreeDiff *diffAncestorToDest = [COSubtreeDiff diffSubtree: ancestorSubtree
															 withSubtree: destCommitSubtree 
														sourceIdentifier: @"ancestor-dest"];
		
		NSLog(@"ancestor-src diff: %@", diffAncestorToSrc);
		NSLog(@"ancestor-dest diff: %@", diffAncestorToDest);
		
		COSubtreeDiff *merged = [diffAncestorToSrc subtreeDiffByMergingWithDiff: diffAncestorToDest];
		
		if ([merged hasConflicts])
		{
			NSLog(@"Pull failed: merged diff has conflicts: %@", [merged conflicts]);
			return;
		}
		
		NSLog(@"diff from %@ to %@ + %@: %@", ancestor, srcCommit, destCommit, merged);
		
		COSubtree *newCurrentState = [merged subtreeWithDiffAppliedToSubtree: ancestorSubtree];
		
		NSLog(@"selective undo success.");
		
		{
			// Just for debugging, diff the current state against the new state
			COSubtreeDiff *diffCurrentStateToNewCurrentState = [COSubtreeDiff diffSubtree: destCommitSubtree
																			  withSubtree: newCurrentState
																		 sourceIdentifier: @""];
			
			NSLog(@"Finished pull diff: %@", diffCurrentStateToNewCurrentState);
		}
		
		// commit the changes
		
		COUUID *newCommitUUID = [aStore addCommitWithParent: destCommit
												   metadata: nil
													   tree: newCurrentState];
		
		[self setCurrentVersion: newCommitUUID
					  forBranch: destBranch
				updateRedoLimit: YES
				updateUndoLimit: NO];
	}
}

@end
