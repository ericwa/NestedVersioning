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
- (void) _diffCommit: (COUUID *)commitA
		  withCommit: (COUUID *)commitB
			  atPath: (COPath *)currentPath
			   store: (COStore *)aStore
	sourceIdentifier: (id)aSource;

- (NSSet *) embeddedPathsAtPath: (COPath *) aPath;

@end


@implementation COPersistentRootDiff

#pragma mark initializers

- (id) initWithCommit: (COUUID *)commitA
			   commit: (COUUID *)commitB
				store: (COStore *)aStore
	 sourceIdentifier: (id)aSource
{
	SUPERINIT;
	
	subtreeDiffForPath = [[NSMutableDictionary alloc] init];
	diffBaseUUIDForPath = [[NSMutableDictionary alloc] init];
	mergeParentsForNewCommitUUID  = [[NSMutableDictionary alloc] init];
	newCommitUUIDForPath = [[NSMutableDictionary alloc] init];
	
	// Initiate the recursive diff process

	[self _diffCommit: commitA
		   withCommit: commitB
			   atPath: [COPath path]
				store: aStore
	 sourceIdentifier: aSource];
	
	return self;
}

- (void) dealloc
{
	[subtreeDiffForPath release];
	[diffBaseUUIDForPath release];
	[mergeParentsForNewCommitUUID release];
	[newCommitUUIDForPath release];
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
	COPersistentRootDiff *result = [[[self class] alloc] init];
	
	result->subtreeDiffForPath = [[NSMutableDictionary alloc] initWithDictionary: subtreeDiffForPath 
																	   copyItems: YES];	
	result->diffBaseUUIDForPath = [[NSMutableDictionary alloc] initWithDictionary: diffBaseUUIDForPath 
																		copyItems: YES];	
	result->mergeParentsForNewCommitUUID = [[NSMutableDictionary alloc] initWithDictionary: mergeParentsForNewCommitUUID 
																				 copyItems: YES];
	result->newCommitUUIDForPath = [[NSMutableDictionary alloc] initWithDictionary: newCommitUUIDForPath 
																		 copyItems: YES];
	
	return result;
}

+ (COPersistentRootDiff *) diffCommit: (COUUID *)commitA
						   withCommit: (COUUID *)commitB
								store: (COStore *)aStore
					 sourceIdentifier: (id)aSource
{
	return [[[self alloc] initWithCommit: commitA
								  commit: commitB
								   store: aStore
						sourceIdentifier: aSource] autorelease];
}


#pragma mark merge parents

- (NSArray *)mergeParentsForNewCommitUUID: (COUUID *)aUUID
{
	NSArray *result = [mergeParentsForNewCommitUUID objectForKey: aUUID];
	if (result != nil)
	{
		return result;
	}
	else
	{
		return [NSArray array];;
	}
}
	
- (NSArray *)mergeParentsForPath: (COPath *)aPath
{
	COUUID *uuid = [newCommitUUIDForPath objectForKey: aPath];
	
	NSAssert(uuid != nil, @"expected uuid");
	
	return [self mergeParentsForNewCommitUUID: uuid];
}

- (void) addMergeParent: (COUUID *)aUUID
				forPath: (COPath *)aPath
{
	COUUID *uuid = [newCommitUUIDForPath objectForKey: aPath];
	
	NSAssert(uuid != nil, @"expected uuid");
	
	NSMutableArray *array = [mergeParentsForNewCommitUUID objectForKey: uuid];
	if (array == nil)
	{
		array = [NSMutableArray array];
		[mergeParentsForNewCommitUUID setObject: array forKey: uuid];
	}
	[array addObject: aUUID];
}

#pragma mark diff algorithm

- (void) _diffCommonBranch: (COSubtree *)branchInA
		  withCommonBranch: (COSubtree *)branchInB
					atPath: (COPath *)currentPath
					 store: (COStore *)aStore
		  sourceIdentifier: (id)aSource
{
	[self _diffCommit: [[COSubtreeFactory factory] currentVersionForBranch: branchInA]
		   withCommit: [[COSubtreeFactory factory] currentVersionForBranch: branchInB]
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
		[self _diffCommonBranch: [persistentRootA subtreeWithUUID: branchUUID]
			   withCommonBranch: [persistentRootB subtreeWithUUID: branchUUID]
						 atPath: currentPath
						  store: aStore
			   sourceIdentifier: aSource];
	}
}

- (void) _diffCommit: (COUUID *)commitA
		  withCommit: (COUUID *)commitB
			  atPath: (COPath *)currentPath
			   store: (COStore *)aStore
	sourceIdentifier: (id)aSource
{	
	// Get the subtrees referenced by these commits.
	
	COSubtree *contentsA = [aStore treeForCommit: commitA];
	COSubtree *contentsB = [aStore treeForCommit: commitB];
	
	// Diff them 
	
	COSubtreeDiff *contentsABDiff = [COSubtreeDiff diffSubtree: contentsA 
												   withSubtree: contentsB
											  sourceIdentifier: aSource];
	
	// Save stuff
	
	[subtreeDiffForPath setObject: contentsABDiff
						   forKey: currentPath];
	
	[diffBaseUUIDForPath setObject: commitA
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

- (COSubtreeDiff *) subtreeDiffAtPath: (COPath *)aPath
{
	return [subtreeDiffForPath objectForKey: aPath];
}

#pragma mark private

- (NSSet *) embeddedPathsAtPath: (COPath *) aPath
{
	NSMutableSet *result = [NSMutableSet set];
	
	COSubtreeDiff *diff = [subtreeDiffForPath objectForKey: aPath];
	NSAssert(diff != nil, @"expected diff");
	
	for (COSubtreeEdit *edit in diff)
	{
		if ([[edit attribute] isEqual: @"currentVersion"])
		{
			[result addObject: [aPath pathByAppendingPathComponent: [edit UUID]]];
		}
	}
	
	return result;
}


#pragma mark diff application

- (COUUID *) _applyAtPath: (COPath *)aPath
					store: (COStore *)aStore
{
	
}


- (COUUID *) commitInStore: (COStore *)aStore
{
	if ([self hasConflicts])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"conflicts must be resolved before the diff can be applied"];
	}
	
	COSubtree *dest = [aStore treeForCommit: aParent];
	
	COSubtreeDiff *rootDiff = [subtreeDiffForPath objectForKey: [COPath path]];
	assert(rootDiff != nil);
	assert(![rootDiff hasConflicts]);
	
	COSubtree *result = [rootDiff subtreeWithDiffAppliedToSubtree: dest];
	
	COUUID *newCommitUUID = [aStore addCommitWithParent: aParent
											   metadata: nil
												   tree: result];
	return newCommitUUID;
}


@end
