#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "COUUID.h"
#import "COStorePrivate.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtree.h"
#import "COSubtreeDiff.h"
#import "COPersistentRootDiff.h"

@implementation COSubtreeFactory (Pull)

- (void) pullChangesFromBranch: (COSubtree*)srcBranch
					  toBranch: (COSubtree*)destBranch
						 store: (COStore *)aStore
{
	ETUUID *srcCommit = [self currentVersionForBranch: srcBranch];
	ETUUID *destCommit = [self currentVersionForBranch: destBranch];
	
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
		
		ETUUID *ancestor = [aStore commonAncestorForCommit: srcCommit
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
		
		COPersistentRootDiff *diffAncestorToSrc = [COPersistentRootDiff diffSubtree: ancestorSubtree
																		withSubtree: srcCommitSubtree 
																			  store: aStore
																   sourceIdentifier: @"ancestor-src"];	
		COPersistentRootDiff *diffAncestorToDest = [COPersistentRootDiff diffSubtree: ancestorSubtree
																		 withSubtree: destCommitSubtree 
																			   store: aStore
																	sourceIdentifier: @"ancestor-dest"];
		
		NSLog(@"ancestor-src diff: %@", diffAncestorToSrc);
		NSLog(@"ancestor-dest diff: %@", diffAncestorToDest);
		
		COPersistentRootDiff *merged = [diffAncestorToSrc persistentRootDiffByMergingWithDiff: diffAncestorToDest];
		
		if ([merged hasConflicts])
		{
			NSLog(@"Pull failed: merged diff has conflicts: %@", [merged conflicts]);
			return;
		}
				
		NSLog(@"diff from %@ to %@ + %@: %@", ancestor, srcCommit, destCommit, merged);
	
		// commit the changes
		
		COUUID *newCommitUUID = [merged commitAppliedToParent: destCommit
														store: aStore];
		
		[self setCurrentVersion: newCommitUUID
					  forBranch: destBranch
				updateRedoLimit: YES
				updateUndoLimit: NO];
	}
}

@end
