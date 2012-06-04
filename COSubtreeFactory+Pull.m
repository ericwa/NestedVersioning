#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "COUUID.h"

#import "COSubtreeFactory.h"
#import "COSubtree.h"
#import "COSubtreeDiff.h"
#import "COPersistentRootDiff.h"

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
		
		COPersistentRootDiff *diffAncestorToSrc = [COPersistentRootDiff diffCommit: ancestor
																		withCommit: srcCommit
																			  store: aStore
																   sourceIdentifier: @"ancestor-src"];	
		COPersistentRootDiff *diffAncestorToDest = [COPersistentRootDiff diffCommit: ancestor
																		 withCommit: destCommit
																			   store: aStore
																	sourceIdentifier: @"ancestor-dest"];
		
		NSLog(@"ancestor-src diff: %@", diffAncestorToSrc);
		NSLog(@"ancestor-dest diff: %@", diffAncestorToDest);
		
		COPersistentRootDiff *merged = [diffAncestorToSrc persistentRootDiffByMergingWithDiff: diffAncestorToDest];
		
		if ([merged hasConflicts])
		{
			NSLog(@"Pull failed: merged diff has conflicts");
			return;
		}
				
		NSLog(@"diff from %@ to %@ + %@: %@", ancestor, srcCommit, destCommit, merged);
	
		// commit the changes
		
		COUUID *newCommitUUID = [merged commitInStore: aStore];
		
		[self setCurrentVersion: newCommitUUID
					  forBranch: destBranch
				updateRedoLimit: YES
				updateUndoLimit: NO];
	}
}

@end
