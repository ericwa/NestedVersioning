#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtree.h"

@implementation COSubtreeFactory (Pull)

static BOOL CommitIsParentOfCommit(ETUUID *testChild, ETUUID *testParent, COStore *store)
{	
	ETUUID *temp = testChild;

	do
	{
		if ([temp isEqual: testParent])
		{
			return YES;
		}
		temp = [store parentForCommit: temp];
	}
	while (temp != nil);
	
	return NO;
}

static ETUUID *FindCommonAncestor(ETUUID *commitA, ETUUID *commitB, COStore *store)
{
	NSMutableSet *ancestorsOfA = [NSMutableSet set];
	
	for (ETUUID *temp = commitA; temp != nil; temp = [store parentForCommit: temp])
	{
		[ancestorsOfA addObject: temp];
	}
	
	for (ETUUID *temp = commitB; temp != nil; temp = [store parentForCommit: temp])
	{
		if ([ancestorsOfA containsObject: temp])
		{
			return temp;
		}
	}
	
	// No common ancestor
	return nil;
}

- (void) pullChangesFromBranch: (COSubtree*)srcBranch
					  toBranch: (COSubtree*)destBranch
						 store: (COStore *)aStore
{
	ETUUID *srcCommit = [self currentVersionForBranch: srcBranch];
	ETUUID *destCommit = [self currentVersionForBranch: destBranch];
	
	if (CommitIsParentOfCommit(srcCommit, destCommit, aStore))
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
		
		ETUUID *ancestor = FindCommonAncestor(srcCommit, destCommit, aStore);
		
		NSLog(@"common ancestor: %@", ancestor);
		
		/**
		 * now, open up the two branches, and do a merge.
		 *
		 * note that we need a special merge strategy for merging branch objects:
		 * call this method recursively!
		 */
	}

}

@end
