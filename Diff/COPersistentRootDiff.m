#import "COPersistentRootDiff.h"
#import "COMacros.h"
#import "COPath.h"

#import "COPersistentRootEditingContext.h"
#import "COSubtreeDiff.h"
#import "COSubtreeEdits.h"

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
		
	for (COPath *childPath in [self embeddedPathsAtPath: currentPath])
	{
		COUUID *branchUUID = [childPath lastPathComponent];
		
		[self _diffCommit: [[COSubtreeFactory factory] currentVersionForBranch: [contentsA subtreeWithUUID: branchUUID]]
			   withCommit: [[COSubtreeFactory factory] currentVersionForBranch: [contentsB subtreeWithUUID: branchUUID]]
				   atPath: childPath
					store: aStore
		 sourceIdentifier: aSource];
	}
}

#pragma mark merge algorithm

- (BOOL) isConflict: (COSubtreeConflict *)aConflict
   editingAttribute: (NSString *)attribute
{
	if ([[aConflict allEdits] count] == 0)
		return NO;
	
	for (COSubtreeEdit *edit in [aConflict allEdits])
	{
		if (![[edit attribute] isEqualToString: attribute])
			return NO;
	}
	
	return YES;
}

- (void) _mergePersistentRootDiff: (COPersistentRootDiff *)other
						   atPath: (COPath *)currentPath
{	
	COSubtreeDiff *contentsAdiff = [self subtreeDiffAtPath: currentPath];
	COSubtreeDiff *contentsBdiff = [other subtreeDiffAtPath: currentPath];
	
	if (nil == contentsAdiff || nil == contentsBdiff)
	{
		[NSException raise: NSInternalInconsistencyException format: @"unexpected nil"];
	}
	
	COSubtreeDiff *merged = [contentsAdiff subtreeDiffByMergingWithDiff: contentsBdiff];

	if ([merged hasConflicts])
	{
		for (COSubtreeConflict *conflict in [NSSet setWithSet: [merged valueConflicts]])
		{
			if ([self isConflict: conflict editingAttribute: kCOCurrentVersion])
			{					
				COUUID *branchUUID = [[[conflict allEdits] anyObject] UUID];					
				NSAssert(branchUUID != nil, @"");
				
				COPath *branchPath = [currentPath pathByAppendingPathComponent: branchUUID];
				

				// FIXME: only works for one merge right now, because we assume the currentVersion changes
				// were all real commits.
				
				COUUID *pendingCommitUUID = [COUUID UUID];
				// needed by addMergeParent:forPath:
				[newCommitUUIDForPath setObject: pendingCommitUUID
										 forKey: branchPath];

				// record merge parents				
				
				for (COSetAttribute *edit in [conflict allEdits])
				{					
					COUUID *commitUUID = [edit value];
					NSAssert([commitUUID isKindOfClass: [COUUID class]], @"");
					[self addMergeParent: commitUUID forPath: branchPath];
				}
				
				// create a new setValueEdit
				
				
				COSetAttribute *newEdit = [[[COSetAttribute alloc] initWithUUID: branchUUID
																	  attribute: kCOCurrentVersion
															   sourceIdentifier: @"virtual"
																		   type: [COType commitUUIDType]
																		  value: pendingCommitUUID] autorelease];
				
				[merged removeConflict: conflict];
				[merged addEdit: newEdit];				
				

					
				// Recursive call
				[self _mergePersistentRootDiff: other
									   atPath: branchPath];
			}
		}
		
		for (COSubtreeConflict *conflict in [NSSet setWithSet: [merged valueConflicts]])
		{
			if ([self isConflict: conflict editingAttribute: @"head"])
			{					
				COUUID *branchUUID = [[[conflict allEdits] anyObject] UUID];					
				NSAssert(branchUUID != nil, @"");
				
				COPath *branchPath = [currentPath pathByAppendingPathComponent: branchUUID];
				COUUID *pendingCommitUUID = [newCommitUUIDForPath objectForKey: branchPath];
				
				COSetAttribute *newEdit = [[[COSetAttribute alloc] initWithUUID: branchUUID
																	  attribute: @"head"
															   sourceIdentifier: @"virtual"
																		   type: [COType commitUUIDType]
																		  value: pendingCommitUUID] autorelease];
				
				[merged removeConflict: conflict];
				[merged addEdit: newEdit];
			}
		}
	}
					 
	[subtreeDiffForPath setObject: merged
						   forKey: currentPath];
}


- (void)mergeWithDiff: (COPersistentRootDiff *)other
{
	[self _mergePersistentRootDiff: other
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

- (NSSet *) conflicts
{
	NSMutableSet *result = [NSMutableSet set];
	for (COSubtreeDiff *diff in [subtreeDiffForPath allValues])
	{
		[result unionSet: [diff conflicts]];
	}
	return [NSSet setWithSet: result];
}
- (BOOL) hasEdits
{
	for (COSubtreeDiff *diff in [subtreeDiffForPath allValues])
	{
		if ([[diff allEdits] count] != 0)
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
	
	for (COSubtreeEdit *edit in [diff allEdits])
	{
		if ([[edit attribute] isEqual: kCOCurrentVersion])
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
	// recursively apply the child commits
	
	for (COPath *childPath in [self embeddedPathsAtPath: aPath])
	{
		BOOL hasDiffBaseUUIDForChildPath = (nil != [diffBaseUUIDForPath objectForKey: childPath]);
		BOOL hasSubtreeDiffChildPath = (nil != [subtreeDiffForPath objectForKey: childPath]);
		
		assert(hasSubtreeDiffChildPath == hasDiffBaseUUIDForChildPath);
		
		if (hasSubtreeDiffChildPath)
		{
			[self _applyAtPath: childPath store: aStore];
		}
		else
		{
			NSLog(@"Ignoring child path %@ because we have no info for it (means it was handled implicitly)", childPath);
		}
	}
	
	// apply self
	
	COSubtreeDiff *diff = [self subtreeDiffAtPath: aPath];
	COUUID *commit = [diffBaseUUIDForPath objectForKey: aPath];
	
	COSubtree *dest = [aStore treeForCommit: commit];
	COSubtree *result = [diff subtreeWithDiffAppliedToSubtree: dest];

	COUUID *targetUUID = [newCommitUUIDForPath objectForKey: aPath];
	
	if (targetUUID == nil)
	{
		NSLog(@"generate new commit UUID for %@", aPath);
		targetUUID = [COUUID UUID];
	}
	else
	{
		NSLog(@"using %@ for %@", targetUUID, aPath);
	}

	
	COUUID *newCommitUUID = [aStore addCommitWithUUID: targetUUID
										   parent: commit
											 metadata: nil
												 tree: result];
	
	return newCommitUUID;
}


- (COUUID *) commitInStore: (COStore *)aStore
{
	if ([self hasConflicts])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"conflicts must be resolved before the diff can be applied"];
	}
	
	return [self _applyAtPath: [COPath path] store: aStore];
}


@end
