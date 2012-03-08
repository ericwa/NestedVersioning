#import "COPersistentRootDiff.h"
#import "COMacros.h"
#import "COPath.h"
#import "COStorePrivate.h"
#import "COPersistentRootEditingContext.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtreeDiff.h"

@interface COPersistentRootDiff (Private)
- (void) _diffCommonBranch: (COSubtree *)branchInA
		  withCommonBranch: (COSubtree *)branchInB
					atPath: (COPath *)currentPath
					 store: (COStore *)aStore;
- (void) _diffCommonPersistentRoot: (COSubtree *)persistentRootA
		  withCommonPersistentRoot: (COSubtree *)persistentRootB
							atPath: (COPath *)currentPath
							 store: (COStore *)aStore;
- (void) recordPersistentRootContentsDiff: (COSubtreeDiff *)contentsDiff forPath: (COPath *)aPath;
- (void) _diffContent: (COSubtree *)contentsA
		  withContent: (COSubtree *)contentsB
			   atPath: (COPath *)currentPath
				store: (COStore *)aStore;
@end


@implementation COPersistentRootDiff

#pragma mark initializers

- (id) initWithBranchOrPersistentRoot: (COSubtree *)branchOrPersistentRootA
			   branchOrPersistentRoot: (COSubtree *)branchOrPersistentRootB
								store: (COStore *)aStore
{
	SUPERINIT;
	
	initialSubtreeForPath = [[NSMutableDictionary alloc] init];
	subtreeDiffForPath = [[NSMutableDictionary alloc] init];
	
	// "pending" commits created by merge
	
	parentCommitForPendingCommitUUID = [[NSMutableDictionary alloc] init];
	treeToCommitForPendingCommitUUID = [[NSMutableDictionary alloc] init];
	
	wasCreatedFromBranches = [[COSubtreeFactory factory] isBranch: branchOrPersistentRootA];
		

	// Diff the root item
	
	ASSIGN(rootDiff, [COSubtreeDiff diffSubtree: branchOrPersistentRootA
									withSubtree: branchOrPersistentRootB]);
	
	// Initiate the recursive diff process

	if (wasCreatedFromBranches)
	{
		[self _diffCommonBranch: branchOrPersistentRootA
			   withCommonBranch: branchOrPersistentRootB
						 atPath: [COPath path]
						  store: aStore];
	}
	else
	{
		[self _diffCommonPersistentRoot: branchOrPersistentRootA
			   withCommonPersistentRoot: branchOrPersistentRootB
								 atPath: [COPath path]
								  store: aStore];
	}
	
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	COPersistentRootDiff *result = [[[self class] alloc] init];

	result->initialSubtreeForPath = [[NSMutableDictionary alloc] initWithDictionary: initialSubtreeForPath 
																	   copyItems: YES];
	result->subtreeDiffForPath = [[NSMutableDictionary alloc] initWithDictionary: subtreeDiffForPath 
																	   copyItems: YES];
	result->parentCommitForPendingCommitUUID = [[NSMutableDictionary alloc] initWithDictionary: parentCommitForPendingCommitUUID 
																					 copyItems: YES];
	result->treeToCommitForPendingCommitUUID = [[NSMutableDictionary alloc] initWithDictionary: treeToCommitForPendingCommitUUID 
																					 copyItems: YES];

	result->wasCreatedFromBranches = wasCreatedFromBranches;
	result->rootDiff = [rootDiff copyWithZone: zone];
	return result;
}

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
		return [[[self alloc] initWithBranchOrPersistentRoot: rootA
									  branchOrPersistentRoot: rootB
													   store: aStore] autorelease];
	}
}


+ (COPersistentRootDiff *) diffBranch: (COSubtree *)branchA
						   withBranch: (COSubtree *)branchB
								store: (COStore *)aStore
{
	return [[[self alloc] initWithBranchOrPersistentRoot: branchA
								  branchOrPersistentRoot: branchB
												   store: aStore] autorelease];
	
}


#pragma mark diff application

- (void) applyToPersistentRootOrBranch: (COSubtree *)dest
								 store: (COStore *)aStore
{
	if (wasCreatedFromBranches != [[COSubtreeFactory factory] isBranch: dest])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"persistent root diff must be applied to the same type of object it was created from"];
	}
	if ([self hasConflicts])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"conflicts must be resolved before the diff can be applied"];
	}
	
	[rootDiff applyTo: dest];
	
	// If the receiver was created as a result of a merge, there will be
	// "synthesized" commits referenced in the subtree that will not
	// be present in the store. we need to commit them.
	
	for (ETUUID *commitUUID in treeToCommitForPendingCommitUUID)
	{
		[aStore addCommitWithParent: [parentCommitForPendingCommitUUID objectForKey: commitUUID]
						   metadata: nil
							   tree: [treeToCommitForPendingCommitUUID objectForKey: commitUUID]];
	}
}

#pragma mark diff algorithm


- (void) _diffCommonBranch: (COSubtree *)branchInA
		  withCommonBranch: (COSubtree *)branchInB
					atPath: (COPath *)currentPath
					 store: (COStore *)aStore
{
	// PRECONDITIONS: assume branchA and branchB point to related (but divergent) versions of a persistent root
	
	ETUUID *versionA = [[COSubtreeFactory factory] currentVersionForBranch: branchInA];
	ETUUID *versionB = [[COSubtreeFactory factory] currentVersionForBranch: branchInB];
	
	// Get the subtrees referenced by these commits.
	
	COSubtree *subcontentsA = [aStore treeForCommit: versionA];
	COSubtree *subcontentsB = [aStore treeForCommit: versionB];
	
	
	[self _diffContent: subcontentsA
		   withContent: subcontentsB
				atPath: [currentPath pathByAppendingPathComponent: [branchInA UUID]]
				 store: aStore];
}

/**
 * diffs ALL branches of the given persistent root.
 */
- (void) _diffCommonPersistentRoot: (COSubtree *)persistentRootA
		  withCommonPersistentRoot: (COSubtree *)persistentRootB
							atPath: (COPath *)currentPath
							 store: (COStore *)aStore
{
	// OK, for now we'll implement the diff all branches policy.
	
	// Find all common branches (non-in-common ones handled implicitly)		
	
	NSSet *allBranchUUIDsA = [[COSubtreeFactory factory] brancheUUIDsOfPersistentRoot: persistentRootA];
	NSSet *allBranchUUIDsB = [[COSubtreeFactory factory] brancheUUIDsOfPersistentRoot: persistentRootB];
	
	// Those which are only in A or only in B are handled implicitly by contentsABDiff
	
	NSMutableSet *branchesIntersection = [NSMutableSet setWithSet: allBranchUUIDsA];
	[branchesIntersection intersectSet: allBranchUUIDsB];
	
	for (ETUUID *branchUUID in branchesIntersection)
	{
		COSubtree *branchInA = [persistentRootA subtreeWithUUID: branchUUID];
		COSubtree *branchInB = [persistentRootB subtreeWithUUID: branchUUID];
		
		[self _diffCommonBranch: branchInA
			   withCommonBranch: branchInB
						 atPath: currentPath
						  store: aStore];
	}
}

- (void) _diffContent: (COSubtree *)contentsA
		  withContent: (COSubtree *)contentsB
			   atPath: (COPath *)currentPath
				store: (COStore *)aStore
{		
	// Diff them 
	
	COSubtreeDiff *contentsABDiff = [COSubtreeDiff diffSubtree: contentsA withSubtree: contentsB];
	
	[initialSubtreeForPath setObject: [[contentsA copy] autorelease]
							  forKey: currentPath];
	
	[subtreeDiffForPath setObject: contentsABDiff
						   forKey: currentPath];
	
	
	// Search for all embedded persistent roots.
	
	NSSet *allEmbeddedRootUUIDsA = [[COSubtreeFactory factory] allEmbeddedPersistentRootUUIDsInSubtree: contentsA];
	NSSet *allEmbeddedRootUUIDsB = [[COSubtreeFactory factory] allEmbeddedPersistentRootUUIDsInSubtree: contentsB];
	
	// Those which are only in A or only in B are handled implicitly by contentsABDiff
	
	NSMutableSet *commonEmbeddedPersistentRootUUIDs = [NSMutableSet setWithSet: allEmbeddedRootUUIDsA];
	[commonEmbeddedPersistentRootUUIDs intersectSet: allEmbeddedRootUUIDsB];
	
	for (ETUUID *commonUUID in commonEmbeddedPersistentRootUUIDs)
	{
		[self _diffCommonPersistentRoot: [contentsA subtreeWithUUID: commonUUID]
			   withCommonPersistentRoot: [contentsB subtreeWithUUID: commonUUID]
								 atPath: currentPath
								  store: aStore];
	}
}

#pragma mark merge algorithm

- (void) mergeBranchUUID: (ETUUID *)branchAUUID
		  withBranchUUID: (ETUUID *)branchBUUID
		withSubtreeDiffA: (COSubtreeDiff *)subtreeDiffA
		withSubtreeDiffB: (COSubtreeDiff *)subtreeDiffB
		  initialSubtree: (COSubtree *)initalSubtree
				  atPath: (COPath *)currentPath
				   store: (COStore *)aStore
{
	ETUUID *branchAAndBInitialVersion = nil;
	
	ETUUID *branchACurrentVersion = [[COSubtreeFactory factory] currentVersionForBranch: branchA];
	ETUUID *branchBCurrentVersion = [[COSubtreeFactory factory] currentVersionForBranch: branchB];


	ETUUID *pendingCommitUUID = [ETUUID UUID];
		
	// our commit will be attached to branchACurrentVersion
		
	[parentCommitForPendingCommitUUID setObject: branchACurrentVersion
										forKey: pendingCommitUUID];
	
	// we need to compute a diff which is based on branchAAndBInitialVersion
		
}


/**
 * Take 2 subtree diffs, as well as the corresponding subtrees they are based on,
 * and merge the diffs.
 *
 * Look for conflicting changes to "currentVersion" of branch objects, and resolve
 * them by setting the "currentVersion" to a new random UUID.
 */
- (void) mergePersistentRootDiff: (COPersistentRootDiff *)other
						  atPath: (COPath *)currentPath
						   store: (COStore *)aStore
{	
	COSubtreeDiff *contentsAdiff = [self subtreeDiffAtPath: currentPath];
	COSubtree *contentsA = [self initialSubtreeForPath: currentPath];
	COSubtreeDiff *contentsBdiff = [other subtreeDiffAtPath: currentPath];
	COSubtree *contentsB = [other initialSubtreeForPath: currentPath];
	
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
							  [[conflict editB] editedItemUUID]], @"");  // a concequence of the validity of the conflict

					ETUUID *branchUUID = [[conflict editA] editedItemUUID];
					
					// create a new setValueEdit
					
					ETUUID *tempCommitUUID = [ETUUID UUID];
					id edit = nil;					
					[edit setEditedItemUUID: branchUUID]; 
					[edit setEditedAttribute: @"currentVersion"];
					[edit setValue: tempCommitUUID];
					
					[self recordTemporaryCommit: tempCommitUUID
										forPath: [currentPath pathByAppendingPathComponent: branchUUID]];
					
					
					ETUUID *parentOfCommit = [[conflict editA] value];
					
					[parentCommitForPendingCommitUUID setObject: parentOfCommit
														 forKey: pendingCommitUUID];
					

					
					// Recursive call
					[self mergePath: [currentPath pathByAppendingPathComponent: branchUUID]];
				}
			}
		}
	}
	else
	{
		// FIXME: ... recursive children won't be visited.
		// remove them from subtreeDiffForPath?
	}
					 
	[subtreeDiffForPath setObject: merged
						   forKey: currentPath];
}


- (void)mergeWithDiff: (COPersistentRootDiff *)other
				store: (COStore *)aStore
{
	[self mergePersistentRootDiff: other
						   atPath: [COPath path]
							store: aStore];
}

- (COPersistentRootDiff *)persistentRootDiffByMergingWithDiff: (COPersistentRootDiff *)other
														store: (COStore *)aStore
{
	COPersistentRootDiff *result = [[self copy] autorelease];
	[result mergeWithPersistentRootDiff: other];
	return result;
}

#pragma mark access

- (BOOL) hasConflicts
{
	if ([rootDiff hasConflicts])
		return YES;
	
	for (COSubtreeDiff *diff in [subtreeDiffForPath allValues])
	{
		if ([diff hasConflicts])
			return YES;
	}
	
	return NO;
}

/**
 * always returns the empty path, at a minimum
 */
- (NSSet *) paths
{
	return [NSSet setWithArray: [subtreeDiffForPath allKeys]];
}

- (COSubtreeDiff *) rootSubtreeDiff
{
	return rootDiff;
}

- (COSubtreeDiff *) subtreeDiffAtPath: (COPath *)aPath
{
	// FIXME: mutable?
	return [subtreeDiffForPath objectForKey: aPath];
}

- (COSubtree *) initialSubtreeForPath: (COPath *)aPath
{
	return [[[initialSubtreeForPath objectForKey: aPath] copy] autorelease];
}


@end
