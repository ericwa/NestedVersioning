#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtree.h"

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
	}

}

@end
