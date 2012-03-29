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
					 store: (COStore *)aStore
		  sourceIdentifier: (id)aSource;
- (void) _diffCommonPersistentRoot: (COSubtree *)persistentRootA
		  withCommonPersistentRoot: (COSubtree *)persistentRootB
							atPath: (COPath *)currentPath
							 store: (COStore *)aStore
				  sourceIdentifier: (id)aSource;
- (void) recordPersistentRootContentsDiff: (COSubtreeDiff *)contentsDiff forPath: (COPath *)aPath;
- (void) _diffContent: (COSubtree *)contentsA
		  withContent: (COSubtree *)contentsB
			   atPath: (COPath *)currentPath
				store: (COStore *)aStore
	 sourceIdentifier: (id)aSource;
@end


@implementation COPersistentRootDiff

#pragma mark initializers

- (id) initWithBranchOrPersistentRoot: (COSubtree *)branchOrPersistentRootA
			   branchOrPersistentRoot: (COSubtree *)branchOrPersistentRootB
								store: (COStore *)aStore
					 sourceIdentifier: (id)aSource
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
									withSubtree: branchOrPersistentRootB
							   sourceIdentifier: aSource]);
	
	// Initiate the recursive diff process

	if (wasCreatedFromBranches)
	{
		[self _diffCommonBranch: branchOrPersistentRootA
			   withCommonBranch: branchOrPersistentRootB
						 atPath: [COPath path]
						  store: aStore
			   sourceIdentifier: aSource];
	}
	else
	{
		[self _diffCommonPersistentRoot: branchOrPersistentRootA
			   withCommonPersistentRoot: branchOrPersistentRootB
								 atPath: [COPath path]
								  store: aStore
					   sourceIdentifier: aSource];
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
							 sourceIdentifier: (id)aSource
{
	if (!allBranches)
	{
		COSubtree *branchA = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: rootA];
		COSubtree *branchB = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: rootB];
		
		return [self diffBranch: branchA withBranch: branchB store: aStore sourceIdentifier: aSource];
	}
	else
	{
		return [[[self alloc] initWithBranchOrPersistentRoot: rootA
									  branchOrPersistentRoot: rootB
													   store: aStore
											sourceIdentifier: aSource] autorelease];
	}
}


+ (COPersistentRootDiff *) diffBranch: (COSubtree *)branchA
						   withBranch: (COSubtree *)branchB
								store: (COStore *)aStore
					 sourceIdentifier: (id)aSource
{
	return [[[self alloc] initWithBranchOrPersistentRoot: branchA
								  branchOrPersistentRoot: branchB
												   store: aStore
										sourceIdentifier: aSource] autorelease];
	
}


#pragma mark diff application

- (COSubtree *) subtreeByApplyingToPersistentRootOrBranch: (COSubtree *)dest
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
	
	COSubtree *result = [rootDiff subtreeWithDiffAppliedToSubtree: dest];
	
	// If the receiver was created as a result of a merge, there will be
	// "synthesized" commits referenced in the subtree that will not
	// be present in the store. we need to commit them.
	
	for (COUUID *commitUUID in treeToCommitForPendingCommitUUID)
	{
		[aStore addCommitWithParent: [parentCommitForPendingCommitUUID objectForKey: commitUUID]
						   metadata: nil
							   tree: [treeToCommitForPendingCommitUUID objectForKey: commitUUID]];
	}
	return result;
}

#pragma mark diff algorithm


- (void) _diffCommonBranch: (COSubtree *)branchInA
		  withCommonBranch: (COSubtree *)branchInB
					atPath: (COPath *)currentPath
					 store: (COStore *)aStore
		  sourceIdentifier: (id)aSource
{
	// PRECONDITIONS: assume branchA and branchB point to related (but divergent) versions of a persistent root
	
	COUUID *versionA = [[COSubtreeFactory factory] currentVersionForBranch: branchInA];
	COUUID *versionB = [[COSubtreeFactory factory] currentVersionForBranch: branchInB];
	
	// Get the subtrees referenced by these commits.
	
	COSubtree *subcontentsA = [aStore treeForCommit: versionA];
	COSubtree *subcontentsB = [aStore treeForCommit: versionB];
	
	
	[self _diffContent: subcontentsA
		   withContent: subcontentsB
				atPath: [currentPath pathByAppendingPathComponent: [branchInA UUID]]
				 store: aStore
	  sourceIdentifier: aSource];
}

/**
 * diffs ALL branches of the given persistent root.
 */
- (void) _diffCommonPersistentRoot: (COSubtree *)persistentRootA
		  withCommonPersistentRoot: (COSubtree *)persistentRootB
							atPath: (COPath *)currentPath
							 store: (COStore *)aStore
				  sourceIdentifier: (id)aSource
{
	// OK, for now we'll implement the diff all branches policy.
	
	// Find all common branches (non-in-common ones handled implicitly)		
	
	NSSet *allBranchUUIDsA = [[COSubtreeFactory factory] brancheUUIDsOfPersistentRoot: persistentRootA];
	NSSet *allBranchUUIDsB = [[COSubtreeFactory factory] brancheUUIDsOfPersistentRoot: persistentRootB];
	
	// Those which are only in A or only in B are handled implicitly by contentsABDiff
	
	NSMutableSet *branchesIntersection = [NSMutableSet setWithSet: allBranchUUIDsA];
	[branchesIntersection intersectSet: allBranchUUIDsB];
	
	for (COUUID *branchUUID in branchesIntersection)
	{
		COSubtree *branchInA = [persistentRootA subtreeWithUUID: branchUUID];
		COSubtree *branchInB = [persistentRootB subtreeWithUUID: branchUUID];
		
		[self _diffCommonBranch: branchInA
			   withCommonBranch: branchInB
						 atPath: currentPath
						  store: aStore
			   sourceIdentifier: aSource];
	}
}

- (void) _diffContent: (COSubtree *)contentsA
		  withContent: (COSubtree *)contentsB
			   atPath: (COPath *)currentPath
				store: (COStore *)aStore
	 sourceIdentifier: (id)aSource
{		
	// Diff them 
	
	COSubtreeDiff *contentsABDiff = [COSubtreeDiff diffSubtree: contentsA 
												   withSubtree: contentsB
											  sourceIdentifier: aSource];
	
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
	
	for (COUUID *commonUUID in commonEmbeddedPersistentRootUUIDs)
	{
		[self _diffCommonPersistentRoot: [contentsA subtreeWithUUID: commonUUID]
			   withCommonPersistentRoot: [contentsB subtreeWithUUID: commonUUID]
								 atPath: currentPath
								  store: aStore
					   sourceIdentifier: aSource];
	}
}

#pragma mark merge algorithm

- (BOOL) isConflictEditingCurrentVersionAttribute: (COSubtreeConflict *)aConflict
{
	for (COSubtreeEdit *edit in [aConflict allEdits])
	{
		if (![[edit attribute] isEqualToString: @"currentVersion"])
			return NO;
	}
	return YES;
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
{	
	COSubtreeDiff *contentsAdiff = [self subtreeDiffAtPath: currentPath];
	COSubtree *contentsA = [self initialSubtreeForPath: currentPath];
	COSubtreeDiff *contentsBdiff = [other subtreeDiffAtPath: currentPath];
	COSubtree *contentsB = [other initialSubtreeForPath: currentPath];
	
	if (nil == contentsAdiff || nil == contentsA || nil == contentsBdiff || nil == contentsB)
	{
		[NSException raise: NSInternalInconsistencyException format: @"unexpected nil"];
	}
	
	
	COSubtreeDiff *merged = [contentsAdiff subtreeDiffByMergingWithDiff: contentsBdiff];
	
	// now look for conflicts...
	
	if ([merged hasConflicts])
	{
		for (COSubtreeConflict *conflict in [NSSet setWithSet: [merged valueConflicts]])
		{
			// This algorithm only really supports pairs of conflicting edits (i.e. merging exactly 2 roots and resolving all conflicts)
			
			// Look for conflicts where both sides modified the currentVersion of a branch
			
			if ([self isConflictEditingCurrentVersionAttribute: conflict])
			{
				COSubtree *branchA = [contentsA subtreeWithUUID: [[conflict editA] editedItemUUID]];
				COSubtree *branchB = [contentsB subtreeWithUUID: [[conflict editB] editedItemUUID]];
			
				if ([[COSubtreeFactory factory] isBranch: branchA] &&
					[[COSubtreeFactory factory] isBranch: branchB])
				{
					[merged removeConflict: conflict];
					
					NSAssert([[[conflict editA] editedItemUUID] isEqual: 
							  [[conflict editB] editedItemUUID]], @"");  // a concequence of the validity of the conflict

					COUUID *branchUUID = [[conflict editA] editedItemUUID];
					
					// create a new setValueEdit
					
					COUUID *pendingCommitUUID = [COUUID UUID];
					id edit = nil;					
					[edit setEditedItemUUID: branchUUID]; 
					[edit setEditedAttribute: @"currentVersion"];
					[edit setValue: pendingCommitUUID];
					
					[self recordTemporaryCommit: pendingCommitUUID
										forPath: [currentPath pathByAppendingPathComponent: branchUUID]];
					
					
					COUUID *parentOfCommit = [[conflict editA] value];
					
					[parentCommitForPendingCommitUUID setObject: parentOfCommit
														 forKey: pendingCommitUUID];
					
					// Recursive call
					[self mergePersistentRootDiff: other
										   atPath: [currentPath pathByAppendingPathComponent: branchUUID]];
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
{
	[self mergePersistentRootDiff: other
						   atPath: [COPath path]];
}

- (COPersistentRootDiff *)persistentRootDiffByMergingWithDiff: (COPersistentRootDiff *)other
{
	COPersistentRootDiff *result = [[self copy] autorelease];
	[result mergeWithDiff: other];
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
