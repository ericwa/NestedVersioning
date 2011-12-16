#import "COStore+PersistentRootCommit.h"
#import "COMacros.h"

@implementation COStore (PersistentRootCommit)

/**
 * @returns the commit UUID which the path leads to. 
 *
 * Throws an exception if there is an error while navigating the path (similar to
 * opening a filesystem path that does not exist), or if the path has
 * -[COPath hasLeadingPathsToParent] == TRUE or is nil.
 */
- (ETUUID *) baseCommitForPath: (COPath*)aPath
{
#if 0	
	NILARG_EXCEPTION_TEST(aPath);
	NILARG_EXCEPTION_TEST(self);
	if ([aPath hasLeadingPathsToParent])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ called with a path with leading '..'", NSStringFromSelector(_cmd)];
	}
	
	if ([aPath isEmpty])
	{
		// may be nil
		return [self rootVersion];
	}
	
	COPath *parentPath = [aPath pathByDeletingLastPathComponent];
	ETUUID *lastPathComponent = [aPath lastPathComponent];
	ETUUID *parentCommit = [self _baseCommitForPath: parentPath store: self]; // recursive call
	
	COItem *item = [self storeItemForEmbeddedObject: lastPathComponent
											 inCommit: parentCommit];
	
	// item may be a persistent root or a branch.
	
	if ([[item valueForAttribute: @"type"] isEqual: @"persistentRoot"])
	{
		COPath *currentBranchPath = [item valueForAttribute: @"currentBranch"];
		if (![currentBranchPath isKindOfClass: [COPath class]]
			|| ![currentBranchPath hasComponents]
			|| [currentBranchPath hasLeadingPathsToParent]
			|| ![[currentBranchPath pathByDeletingLastPathComponent] isEmpty])
		{
			[NSException raise: NSInvalidArgumentException
						format: @"persistent root at %@ has invalid or no current branch (%@)",
			 aPath, currentBranchPath];
		}
		
		ETUUID *currentBranch = [currentBranchPath lastPathComponent];
		
		item = [self storeItemForEmbeddedObject: currentBranch
										 inCommit: parentCommit];
	}
	
	ETUUID *trackedVersion = [item valueForAttribute: @"currentVersion"];	
	
	if (![[item valueForAttribute: @"type"] isEqual: @"branch"]
		|| ![[item typeForAttribute: @"currentVersion"] isEqual: [COType commitUUIDType]]
		|| (nil == trackedVersion))
	{
		[NSException raise: NSInvalidArgumentException
					format: @"branch specified by %@ is invalid/has no current version set", aPath];
	}
	
	return trackedVersion;
#endif
	return nil;
}


- (ETUUID *) commitWithMetadata: (COMutableItem *)aTree
{
#if 0
	//
	// <<<<<<<<<<<<<<<<<<<<< LOCK DB, BEGIN TRANSACTION <<<<<<<<<<<<<<<<<<<<<
	//
	
	// we need to check if we need to merge, first.
	
	
	ETUUID *newBase;
	
	@try
	{
		newBase = [[self class] _baseCommitForPath: [self path] store: [self store]];
	}
	@catch (NSException *exception)
	{
		NSLog(@"WARNING: Exception occurred while calling +[COPersistentRootEditingContext _baseCommitForPath: %@ store: %@]: %@", [self path], [self store], exception);
		
		// This means one of the persistent roots we will need to update to make the commit has been
		// corrupted/deleted since the context was created.
		// There isn't much we can do... it won't be possible to commit our changes.
		
		// FIXME: remove
		assert(0);
		
		return nil;
	}
	
	if (baseCommit != nil && 
		![newBase isEqual: baseCommit])
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"Merging not yet supported"];
	}
	
	
	// calculate final uuid set
	assert(rootItemUUID != nil);
	NSSet *finalUUIDSet = [[self _allEmbeddedObjectUUIDsForUUID: rootItemUUID] setByAddingObject: rootItemUUID];
	
	// set up the commit dictionary
	NSMutableDictionary *uuidsanditems = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in finalUUIDSet)
		{
			COMutableItem *item = [self _storeItemForUUID: uuid];
			
			[uuidsanditems setObject: item
							  forKey: uuid];
		}
	}
	
	// FIXME
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	
	// This is kind of a hack. If we are committing to the top-level of the store,
	// which is conceptually unversioned, don't set a parent pointer on the commit.
	// This will ensure old versions get GC'ed.
	ETUUID *commitParent = baseCommit;
	if ([path isEmpty])
	{
		commitParent = nil;
	}
	
	ETUUID *newCommitUUID = [store addCommitWithParent: commitParent
											  metadata: md
									UUIDsAndStoreItems: uuidsanditems
											  rootItem: rootItemUUID];
	
	
	assert(newCommitUUID != nil);
	
	if ([path isEmpty])
	{
		[store setRootVersion: newCommitUUID];
	}
	
	
	//
	// >>>>>>>>>>>>>>>>>>>>> UNLOCK DB, COMMIT TRANSACTION >>>>>>>>>>>>>>>>>>>>>
	//
	
	// if anything in the transaction failed, we can bail out here.
	
	
	
	
	// now update our path's parent
	
	if (![path isEmpty])
	{
		COPath *parentPath = [path pathByDeletingLastPathComponent];
		ETUUID *ourUUID = [path lastPathComponent];
		
		COPersistentRootEditingContext *parentCtx = [[[self class] alloc] initWithPath: parentPath
																			   inStore: store];
		
		COMutableItem *item = [parentCtx _storeItemForUUID: ourUUID];
		assert(item != nil);
		
		// FIXME: move to COItemFactory or another utility class for dealing with persistent root data structures.
		
		// item may be a persistent root or a branch.
		
		if ([[item valueForAttribute: @"type"] isEqual: @"persistentRoot"])
		{
			COPath *currentBranchPath = [item valueForAttribute: @"currentBranch"];
			ETUUID *currentBranch = [currentBranchPath lastPathComponent];
			assert([[currentBranchPath pathByDeletingLastPathComponent] isEmpty]);
			
			item = [parentCtx _storeItemForUUID: currentBranch];
			assert(item != nil);
		}
		
		assert ([[item valueForAttribute: @"type"] isEqual: @"branch"]);
		assert([[item typeForAttribute: @"currentVersion"] isEqual: [COType commitUUIDType]]);
		
		ETUUID *trackedVersion = [item valueForAttribute: @"currentVersion"];
		assert([trackedVersion isEqual: baseCommit]); // we already checked this earlier
		[item setValue: newCommitUUID forAttribute: @"currentVersion" type: [COType commitUUIDType]];
		[item setValue: newCommitUUID forAttribute: @"head" type: [COType commitUUIDType]];
		
		[parentCtx _insertOrUpdateItems: S(item)];
		
		ETUUID *resultUUID = [parentCtx commitWithMetadata: nil];
		assert (resultUUID != nil);
		
		[parentCtx release];
	}
	
	
	// update our internal state
	
	ASSIGN(baseCommit, newCommitUUID);
	[insertedOrUpdatedItems removeAllObjects];
	
	
	return newCommitUUID;
#endif
	return nil;
}

@end
