#import "COSimpleContext.h"
#import "COMacros.h"
#import "COStorePrivate.h"

@implementation COSimpleContext

/** @taskunit creation */


/**
 * Private init method
 */
- (id)initWithBaseCommit: (ETUUID *)aBase
				 inStore: (COStore *)aStore
{
	NILARG_EXCEPTION_TEST(aStore);
	
    SUPERINIT;
	
	insertedOrUpdatedItems = [[NSMutableDictionary alloc] init];
	
	ASSIGN(baseCommit, aBase);
	ASSIGN(store, aStore);

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
	[baseCommit release];
	[insertedOrUpdatedItems release];
	[rootItemUUID release];
	[super dealloc];
}

- (COStore *) store
{
	return store;
}

/**
 * returns a copy
 */
- (COMutableStoreItem *) _storeItemForUUID: (ETUUID*) aUUID
{
	assert([aUUID isKindOfClass: [ETUUID class]]);
	
	COMutableStoreItem *result = nil;
	
	if (baseCommit != nil)
	{
		result = [[[store storeItemForEmbeddedObject: aUUID inCommit: baseCommit] copy] autorelease];
		assert(result != nil);
	}
	
	COMutableStoreItem *localResult = [[[insertedOrUpdatedItems objectForKey: aUUID] copy] autorelease];
	
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
	
	COMutableStoreItem *item = [self _storeItemForUUID: aUUID];
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
	
	for (COMutableStoreItem *item in items)
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


- (ETUUID *) commitWithMetadata: (COStoreItemTree *)aTree
					 makeOrphan: (BOOL)isOrphan
{
	
	//
	// <<<<<<<<<<<<<<<<<<<<< LOCK DB, BEGIN TRANSACTION <<<<<<<<<<<<<<<<<<<<<
	//
	
	// we need to check if we need to merge, first.
	
	
	ETUUID *newBase = baseCommit;
	
	// calculate final uuid set
	assert(rootItemUUID != nil);
	NSSet *finalUUIDSet = [[self _allEmbeddedObjectUUIDsForUUID: rootItemUUID] setByAddingObject: rootItemUUID];
	
	// set up the commit dictionary
	NSMutableDictionary *uuidsanditems = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in finalUUIDSet)
		{
			COMutableStoreItem *item = [self _storeItemForUUID: uuid];
			
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
	if (isOrphan)
	{
		commitParent = nil;
	}
	
	ETUUID *newCommitUUID = [store addCommitWithParent: commitParent
											  metadata: md
									UUIDsAndStoreItems: uuidsanditems
											  rootItem: rootItemUUID];
	
	
	assert(newCommitUUID != nil);
	
	//if ([path isEmpty])
	//{
	//	[store setRootVersion: newCommitUUID];
	//}
	
	
	//
	// >>>>>>>>>>>>>>>>>>>>> UNLOCK DB, COMMIT TRANSACTION >>>>>>>>>>>>>>>>>>>>>
	//
	
	// if anything in the transaction failed, we can bail out here.
	
	
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
