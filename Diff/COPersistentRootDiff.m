#import "COPersistentRootDiff.h"
#import "COMacros.h"
#import "COPath.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtreeDiff.h"

@implementation COPersistentRootDiff

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

- (void) recordPersistentRootContentsDiff: (COSubtreeDiff *)contentsDiff forPath: (COPath *)aPath
{
	
}

- (void) _diffContent: (COSubtree *)contentsA
		  withContent: (COSubtree *)contentsB
			   atPath: (COPath *)currentPath
				store: (COStore *)aStore
{	
	// Diff them
	
	// FIXME: we need a way to make the subtree diff only look at the current branch of any embedded persistent roots.	
	
	COSubtreeDiff *contentsABDiff = [COSubtreeDiff diffSubtree: contentsA withSubtree: contentsB];
	
	[self recordPersistentRootContentsDiff: contentsABDiff forPath: currentPath];
	
	
	// Search for all embedded persistent roots.
	
	NSSet *allEmbeddedRootUUIDsA = [[COSubtreeFactory factory] allEmbeddedPersistentRootUUIDsInSubtree: contentsA];
	NSSet *allEmbeddedRootUUIDsB = [[COSubtreeFactory factory] allEmbeddedPersistentRootUUIDsInSubtree: contentsB];
	
	// Those which are only in A or only in B are handled implicitly by contentsABDiff
	
	NSMutableSet *commonEmbeddedPersistentRootUUIDs = [NSMutableSet setWithSet: allEmbeddedRootUUIDsA];
	[commonEmbeddedPersistentRootUUIDs intersectSet: allEmbeddedRootUUIDsB];
	
	for (ETUUID *commonUUID in commonEmbeddedPersistentRootUUIDs)
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
			
			// PRECONDITIONS: assume branchA and branchB point to related (but divergent) versions of a persistent root
			
			ETUUID *versionA = [[COSubtreeFactory factory] currentVersionForBranch: branchInA];
			ETUUID *versionB = [[COSubtreeFactory factory] currentVersionForBranch: branchInB];
			
			// Get the subtrees referenced by these commits.
			
			COSubtree *subcontentsA = [aStore treeForCommit: versionA];
			COSubtree *subcontentsB = [aStore treeForCommit: versionB];
			
			
			[self _diffContent: subcontentsA
				   withContent: subcontentsB
						atPath: [currentPath pathByAppendingPathComponent: branchUUID]
						 store: aStore];
		}
	}
}

+ (COPersistentRootDiff *) diffBranch: (COSubtree *)branchA
						   withBranch: (COSubtree *)branchB
								store: (COStore *)aStore
{

	
}



- (COSubtreeDiff *)contentsAdiffForPath: (COPath *)currentPath
{
}

- (COSubtree *)contentsAForPath: (COPath *)currentPath
{
}

- (COSubtreeDiff *)contentsBdiffForPath: (COPath *)currentPath
{
}

- (COSubtree *)contentsBForPath: (COPath *)currentPath
{
}


/**
 * Take 2 subtree diffs, as well as the corresponding subtrees they are based on,
 * and merge the diffs.
 *
 * Look for conflicting changes to "currentVersion" of branch objects, and resolve
 * them by setting the "currentVersion" to a new random UUID.
 */
- (void) mergePath: (COPath *)currentPath
{	
	COSubtreeDiff *contentsAdiff = [self contentsAdiffForPath: currentPath];
	COSubtree *contentsA = [self contentsAForPath: currentPath];
	COSubtreeDiff *contentsBdiff: [self contentsBdiffForPath: currentPath];
	COSubtree *contentsB = [self contentsBForPath: currentPath];
	
	COSubtreeDiff *merged = [contentsAdiff subtreeDiffByMergingWithDiff: contentsBdiff];
	
	// now look for conflicts...
	
	if ([merged hasConflicts])
	{
		for (id conflict in [NSSet setWithSet: [merged conflicts]])
		{
			// This algorithm only really supports pairs of conflicting edits (i.e. merging exactly 2 roots and resolving all conflicts)
			
			// Look for conflicts where both sides modified the currentVersion of a branch
			
			if ([[conflict editA] isSetValueEdit] &&
				[[conflict editB] isSetValueEdit] &&
				[[[conflict editA] editedAttribute] isEqual: @"currentVersion"] &&
				[[[conflict editB] editedAttribute] isEqual: @"currentVersion"])
			{
				COSubtree *branchA = [contentsA subtreeWithUUID: [[conflict editA] editedItemUUID]];
				COSubtree *branchB = [contentsB subtreeWithUUID: [[conflict editB] editedItemUUID]];
			
				if ([[COSubtreeFactory factory] isBranch: branchA] &&
					[[COSubtreeFactory factory] isBranch: branchB])
				{
					[merged removeConflict: conflict];
					
					NSAssert([[[conflict editA] editedItemUUID] isEqual:
							  [[conflict editB] editedItemUUID]], @"");

					ETUUID *branchUUID = [[conflict editA] editedItemUUID];
					
					// create a new setValueEdit
					
					ETUUID *tempCommitUUID = [ETUUID UUID];
					id edit = nil;					
					[edit setEditedItemUUID: branchUUID]; 
					[edit setEditedAttribute: @"currentVersion"];
					[edit setValue: tempCommitUUID];
					
					[self recordTemporaryCommit: tempCommitUUID
										forPath: [currentPath pathByAppendingPathComponent: branchUUID]];
					
					// Recursive call
					[self mergePath: [currentPath pathByAppendingPathComponent: branchUUID]];
				}
			}
		}
	}
					 
	return merged;
}


- (COPersistentRootDiff *)persistentRootDiffByMergingWithDiff: (COPersistentRootDiff *)other
{
	[self mergePath: [COPath path]];
}

@end
