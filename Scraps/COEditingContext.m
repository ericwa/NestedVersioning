#import "COPersistentRootEditingContext.h"
#import "COMacros.h"
#import "COStorePrivate.h"

@implementation COEditingContext

/** @taskunit creation */

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
	
	@try
	{
		// this will be somewhat expensive, but needs to be done - we need to 
		// know what version our context is based on.
		ASSIGN(baseCommit, [[self class] _baseCommitForPath: aPath store: aStore]);
	}
	@catch (NSException *exception)
	{
		NSLog(@"WARNING: Exception occurred while calling +[COPersistentRootEditingContext _baseCommitForPath: %@ store: %@]: %@", aPath, aStore, exception);
		[self release];
		
		// FIXME: remove
		assert(0);
		
		return nil;
	}
	
	
	if (baseCommit != nil)
	{
		ASSIGN(rootItemUUID, [store rootItemForCommit: baseCommit]);
	}
	// if there has never been a commit, rootItem is nil.	
	
    return self;
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
- (COMutableItem *) _storeItemForUUID: (ETUUID*) aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	COMutableItem *localResult = [[[insertedOrUpdatedItems objectForKey: aUUID] mutableCopy] autorelease];
	
	if (localResult != nil)
	{
		return localResult;
	}
	
	if (baseCommit != nil)
	{
		return [[[store storeItemForEmbeddedObject: aUUID inCommit: baseCommit] mutableCopy] autorelease];
	}
	return nil;
}

// FIXME: Duplicate of code in COTreeDiff
- (NSSet *) _allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	NSMutableSet *result = [NSMutableSet set];
	
	COMutableItem *item = [self _storeItemForUUID: aUUID];
	for (NSString *key in [item attributeNames])
	{
		COType *type = [item typeForAttribute: key];
		if ([[type primitiveType] isEqual: [COType embeddedItemType]])
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
	
	for (COMutableItem *item in items)
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





- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot
{
	return [[self class] editingContextForEditingPath: [[self path] pathByAppendingPathComponent: aRoot]
											  inStore: [self store]];
}

- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot
																			onBranch: (ETUUID*)aBranch
{
	// NOTE: We don't use aRoot explicitly. We should use it to do checks.
	// i.e. check that aBranch is in it, etc.
	return [[self class] editingContextForEditingPath: [[self path] pathByAppendingPathComponent: aBranch]
											  inStore: [self store]];
}

- (ETUUID *)rootUUID
{
	return rootItemUUID;
}

- (COMutableItem *)rootItemTree
{
	return [self storeItemTreeForUUID: rootItemUUID];
}

- (COMutableItem *)storeItemTreeForUUID: (ETUUID*) aUUID
{
	/*	NSSet *uuids = [[self _allEmbeddedObjectUUIDsForUUID: aUUID] setByAddingObject: aUUID];
	 
	 NSMutableSet *items = [NSMutableSet set];
	 for (ETUUID *uuid in uuids)
	 {
	 [items addObject: [self _storeItemForUUID: aUUID]];
	 }
	 
	 return [COStoreItemTree itemTreeWithItems: items
	 root: aUUID];
	 */
	return nil;
}

- (void) setItemTree: (COItemTreeNode	*)aTree
{
	NILARG_EXCEPTION_TEST(aTree);
	
	ASSIGN(rootItemUUID, [aTree UUID]);
	
	for (COMutableItem *item in [aTree allContainedStoreItems])
	{
		[insertedOrUpdatedItems setObject: item forKey: [item UUID]];
	}
}

@end