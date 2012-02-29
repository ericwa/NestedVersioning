#import "COPersistentRootDiff.h"
#import "COMacros.h"
#import "COPath.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtreeDiff.h"

@implementation COPersistentRootDiff

/*
+ (COSubtree *) persistentRootOrBranchForPath: (COPath *)aPath inStore: (COStore *)aStore
{
	COPersistentRootEditingContext *ctx = 
	[COPersistentRootEditingContext editingContextForEditingPath: [aPath pathByDeletingLastPathComponent]
														 inStore: aStore];
	
	return [[ctx persistentRootTree] subtreeWithUUID: [aPath lastPathComponent]];
	
}

- (id) initWithPath: (COPath *)aRootOrBranchA
			andPath: (COPath *)aRootOrBranchB
			inStore: (COStore *)aStore
{
	SUPERINIT;
	
	COSubtree *subtreeA = [[self class] persistentRootOrBranchForPath: aRootOrBranchA inStore: aStore];
	COSubtree *subtreeB = [[self class] persistentRootOrBranchForPath: aRootOrBranchB inStore: aStore];
	
	
	if ([[COSubtreeFactory factory] isBranch: subtreeA] && [[COSubtreeFactory factory] isBranch: subtreeB])
	{
		// branch vs branch
		
	}
	else if ([[COSubtreeFactory factory] isPersistentRoot: subtreeA] && [[COSubtreeFactory factory] isPersistentRoot: subtreeB])
	{
		// persistent root vs persistent root
		
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
					format: @"Only branch/branch or proot/proot diff is handled for now."];
	}
	
	
	return self;
}
*/


+ (COPersistentRootDiff *) diffPersistentRoot: (COSubtree *)rootA
						   withPersistentRoot: (COSubtree *)rootB
								  allBranches: (BOOL)allBranches
										store: (COStore *)aStore
{
	if (!allBranches)
	{
		COSubtree *branchA = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: rootA];
		COSubtree *branchB = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: rootB];
		
		return [self diffBranch: branchA withBranch: branchB store: aStore];
	}
	else
	{
		// FIXME:
		return nil;
	}
}

+ (COPersistentRootDiff *) diffBranch: (COSubtree *)branchA
						   withBranch: (COSubtree *)branchB
								store: (COStore *)aStore
{
	// PRECONDITIONS: assume branchA and branchB point to related (but divergent) versions of a persistent root
	
	ETUUID *versionA = [[COSubtreeFactory factory] currentVersionForBranch: branchA];
	ETUUID *versionB = [[COSubtreeFactory factory] currentVersionForBranch: branchB];
	
	// Get the subtrees referenced by these commits.
	
	COSubtree *contentsA = [aStore treeForCommit: versionA];
	COSubtree *contentsB = [aStore treeForCommit: versionB];
	
	// Diff them

	// FIXME: we need a way to make the subtree diff only look at the current branch of any embedded persistent roots.	
	
	COSubtreeDiff *contentsABDiff = [COSubtreeDiff diffSubtree: contentsA withSubtree: contentsB];
	
	// Search for all embedded persistent roots.

	NSSet *allEmbeddedRootUUIDsA = [[COSubtreeFactory factory] allEmbeddedPersistentRootUUUIsInSubtree: contentsA];
	NSSet *allEmbeddedRootUUIDsB = [[COSubtreeFactory factory] allEmbeddedPersistentRootUUIDsInSubtree: contentsB];
	
	// Those which are only in A or only in B are handled implicitly by contentsABDiff

	NSMutableSet *intersection = [NSMutableSet setWithSet: allEmbeddedRootUUIDsA];
	[intersection intersectSet: allEmbeddedRootUUIDsB];
	
	for (ETUUID *commonUUID in intersection)
	{
		// OK, for now we'll implement the diff all branches policy.
		
		// Find all common branches (non-in-common ones handled implicitly)		
		
		NSSet *allBranchUUIDsA = [[COSubtreeFactory factory] brancheUUIDsOfPersistentRoot: [contentsA subtreeWithUUID: commonUUID]];
		NSSet *allBranchUUIDsB = [[COSubtreeFactory factory] brancheUUIDsOfPersistentRoot: [contentsB subtreeWithUUID: commonUUID]];
		
		// Those which are only in A or only in B are handled implicitly by contentsABDiff
		
		NSMutableSet *branchesIntersection = [NSMutableSet setWithSet: allBranchUUIDsA];
		[branchesIntersection intersectSet: allBranchUUIDsB];
		
		for (ETUUID *branchUUID in branchesIntersection)
		{
			COSubtree *branchInA = [contentsA subtreeWithUUID: branchUUID];
			COSubtree *branchInB = [contentsA subtreeWithUUID: branchUUID];
			
			// FIXME: some kind of recursive call here
			
			[self diffBranch: branchInA withBranch: branchInB store: aStore];
		}
	}
	
}


@end
