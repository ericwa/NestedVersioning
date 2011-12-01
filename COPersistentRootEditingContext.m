#import "COPersistentRootEditingContext.h"
#import "Common.h"
#import "COStorePrivate.h"

@implementation COPersistentRootEditingContext

/** @taskunit creation */

+ (ETUUID *) _baseCommitForPath: (COPath*)aPath store: (COStore *)aStore
{
	if ([aPath isEmpty])
	{
		// may be nil
		return [aStore rootVersion];
	}
	else
	{
		COPath *parentPath = [aPath pathByDeletingLastPathComponent];
		ETUUID *lastPathComponent = [aPath lastPathComponent];
		ETUUID *parentCommit = [self _baseCommitForPath: parentPath store: aStore];
		COStoreItem *item = [aStore storeItemForEmbeddedObject: lastPathComponent
													 inCommit: parentCommit];
		
		// FIXME: move to COItemFactory or another utility class for dealing with persistent root data structures.
		
		// item may be a persistent root or a branch.
		
		if ([[item valueForAttribute: @"type"] isEqual: @"persistentRoot"])
		{
			COPath *currentBranchPath = [item valueForAttribute: @"currentBranch"];
			ETUUID *currentBranch = [currentBranchPath lastPathComponent];
			assert([[currentBranchPath pathByDeletingLastPathComponent] isEmpty]);
			
			item = [aStore storeItemForEmbeddedObject: currentBranch
											inCommit: parentCommit];
		}
		
		assert ([[item valueForAttribute: @"type"] isEqual: @"branch"]);
		assert([[item typeForAttribute: @"tracking"] isEqual: COPrimitiveType(kCOPrimitiveTypeCommitUUID)]);
		
		ETUUID *trackedVersion = [item valueForAttribute: @"tracking"];
		assert(trackedVersion != nil);
		
		return trackedVersion;
	}
}

/**
 * Private init method
 */
- (id)initWithPath: (COPath *)aPath
		   inStore: (COStore *)aStore
{
	NILARG_EXCEPTION_TEST(aPath);
	NILARG_EXCEPTION_TEST(aStore);
	
	if ([aPath hasLeadingPathsToParent])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"cannot create context with a path with leading ../"];
	}
	
    SUPERINIT;
	
	insertedOrUpdatedItems = [[NSMutableDictionary alloc] init];
	
	ASSIGN(path, aPath);
	ASSIGN(store, aStore);
	
	// this will be somewhat expensive, but needs to be done - we need to 
	// know what version our context is based on.
	ASSIGN(baseCommit, [[self class] _baseCommitForPath: aPath store: aStore]);
	
	if (baseCommit != nil)
	{
		ASSIGN(rootItemUUID, [store rootItemForCommit: baseCommit]);
	}
	// if there has never been a commit, rootItem is nil.	
	
    return self;
}

+ (COPersistentRootEditingContext *) editingContextForEditingPath: (COPath*)aPath
														  inStore: (COStore *)aStore
{
	return [[[self alloc] initWithPath: aPath
							   inStore: aStore] autorelease];
}


/**
 * private method; public users should use -[COStore rootContext].
 */
+ (COPersistentRootEditingContext *) editingContextForEditingTopLevelOfStore: (COStore *)aStore
{
	return [[self class] editingContextForEditingPath: [COPath path]
											  inStore: aStore];
}

- (void)dealloc
{
	[store release];
	[path release];
	[baseCommit release];
	[insertedOrUpdatedItems release];
	[rootItemUUID release];
	[super dealloc];
}


- (COPath *) path
{
	return path;
}
- (COStore *) store
{
	return store;
}


// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=
// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=
// 
// Private methods
//
// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=
// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=

/**
 * returns a copy
 */
- (COStoreItem *) _storeItemForUUID: (ETUUID*) aUUID
{
	assert([aUUID isKindOfClass: [ETUUID class]]);
	
	COStoreItem *result = nil;
	
	if (baseCommit != nil)
	{
		result = [[[store storeItemForEmbeddedObject: aUUID inCommit: baseCommit] copy] autorelease];
		assert(result != nil);
	}
	
	COStoreItem *localResult = [[[insertedOrUpdatedItems objectForKey: aUUID] copy] autorelease];
	
	if (localResult != nil)
	{
		NSLog(@"overriding %@ with %@", result, localResult);
		result = localResult;
	}
	
	assert(result != nil); // either the store, or in memory, must have the value
	
	return result;
}

- (NSSet *) _allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	NSMutableSet *result = [NSMutableSet set];
	
	COStoreItem *item = [self _storeItemForUUID: aUUID];
	for (NSString *key in [item attributeNames])
	{
		NSDictionary *type = [item typeForAttribute: key];
		if ([[type objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
		{		
			for (ETUUID *embedded in [item allObjectsForAttribute: key])
			{
				[result addObject: embedded];
				[result unionSet: [self _allEmbeddedObjectUUIDsForUUID: embedded]];
			}
		}
	}
	return result;
}

- (void) _insertOrUpdateItems: (NSSet *)items
		newRootEmbeddedObject: (ETUUID*)aRoot
{
	NILARG_EXCEPTION_TEST(items);
	NILARG_EXCEPTION_TEST(aRoot);
	
	assert([items isKindOfClass: [NSSet class]]);
	
	ASSIGN(rootItemUUID, aRoot);
	
	for (COStoreItem *item in items)
	{
		[insertedOrUpdatedItems setObject: item forKey: [item UUID]];
	}
	
	// FIXME: validation
}

- (void) _insertOrUpdateItems: (NSSet *)items
{
	[self _insertOrUpdateItems: items newRootEmbeddedObject: rootItemUUID];
}




// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=
// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=
// 
// COEditingContext protocol
//
// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=
// =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-= =-=-=-=-=-=-=-=-=-=





- (id<COEditingContext>) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot
{
	return [[self class] editingContextForEditingPath: [[self path] pathByAppendingPathComponent: aRoot]
											  inStore: [self store]];
}

- (ETUUID *) commitWithMetadata: (COStoreItemTree *)aTree
{

	//
	// <<<<<<<<<<<<<<<<<<<<< LOCK DB, BEGIN TRANSACTION <<<<<<<<<<<<<<<<<<<<<
	//
	
	// we need to check if we need to merge, first.
	
	
	ETUUID *newBase = [[self class] _baseCommitForPath: [self path] store: [self store]];
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
			COStoreItem *item = [self _storeItemForUUID: uuid];
			
			[uuidsanditems setObject: item
							  forKey: uuid];
		}
	}
	
	// FIXME
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	
	
	ETUUID *newCommitUUID = [store addCommitWithParent: baseCommit
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
		
		COStoreItem *item = [parentCtx _storeItemForUUID: ourUUID];
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
		assert([[item typeForAttribute: @"tracking"] isEqual: COPrimitiveType(kCOPrimitiveTypeCommitUUID)]);
		
		ETUUID *trackedVersion = [item valueForAttribute: @"tracking"];
		assert([trackedVersion isEqual: baseCommit]); // we already checked this earlier
		[item setValue: newCommitUUID forAttribute: @"tracking" type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];
		[item setValue: newCommitUUID forAttribute: @"tip" type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];
		
		[parentCtx _insertOrUpdateItems: S(item)];
		
		ETUUID *resultUUID = [parentCtx commitWithMetadata: nil];
		assert (resultUUID != nil);
		
		[parentCtx release];
	}
	
	
	 // update our internal state
	 
	 ASSIGN(baseCommit, newCommitUUID);
	 [insertedOrUpdatedItems removeAllObjects];
	 
		 
	return newCommitUUID;
}

- (ETUUID *)rootUUID
{
	return rootItemUUID;
}

- (COStoreItemTree *)rootItemTree
{
	return [self storeItemTreeForUUID: rootItemUUID];
}

- (COStoreItemTree *)storeItemTreeForUUID: (ETUUID*) aUUID
{
	NSSet *uuids = [[self _allEmbeddedObjectUUIDsForUUID: aUUID] setByAddingObject: aUUID];
	
	NSMutableSet *items = [NSMutableSet set];
	for (ETUUID *uuid in uuids)
	{
		[items addObject: [self _storeItemForUUID: aUUID]];
	}
		 
	return [COStoreItemTree itemTreeWithItems: items
										 root: aUUID];
}


@end
