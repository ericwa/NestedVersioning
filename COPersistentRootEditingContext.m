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
	
    SUPERINIT;
	
	insertedOrUpdatedItems = [[NSMutableDictionary alloc] init];
	
	ASSIGN(path, aPath);
	ASSIGN(store, aStore);
	
	// this will be somewhat expensive, but needs to be done - we need to 
	// know what version our context is based on.
	ASSIGN(baseCommit, [[self class] _baseCommitForPath: aPath store: aStore]);
	ASSIGN(rootItem, [store rootItemForCommit: baseCommit]);
	
    return self;
}

+ (COPersistentRootEditingContext *) editingContextForEditingPath: (COPath*)aPath
														  inStore: (COStore *)aStore
{
	return [[[self alloc] initWithPath: [COPath path]
							   inStore: aStore] autorelease];}

- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot
{
	return [[self class] editingContextForEditingPath: [[self path] pathByAppendingPathComponent: aRoot]
											  inStore: [self store]];
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
	[rootItem release];
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

- (ETUUID *) commit
{
	/*
FIXME:
	how do we add undo/redo to this?
		for branches/roots that track a specific version, they should also have 
			a key/value called "tip". (terminology stolen from mercurial)
			
			- every commit to that branch root should set both "tracking" and "tip"
			to the same value.
			*/
			
	
	// calculate final uuid set
	assert(rootItem != nil);
	NSSet *finalUUIDSet = [self allEmbeddedObjectUUIDsForUUIDInclusive: rootItem];
	
	// set up the commit dictionary
	NSMutableDictionary *uuidsanditems = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in finalUUIDSet)
		{
			COStoreItem *item = [self storeItemForUUID: uuid];
			
			[uuidsanditems setObject: item
							  forKey: uuid];
		}
	}
	
	// FIXME
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	

	ETUUID *uuid = [store addCommitWithParent: baseCommit
									 metadata: md
						   UUIDsAndStoreItems: uuidsanditems
									 rootItem: rootItem];
	
	assert(uuid != nil);
	
	// FIXME
	
	ASSIGN(baseCommit, uuid);
	[insertedOrUpdatedItems removeAllObjects];

	return uuid;
}

- (void) commitWithMergedVersionUUIDs: (NSArray*)anArray
{
	assert(0); // unimplemented
}

- (ETUUID *)rootEmbeddedObject
{
	return rootItem;
}

- (NSSet *)allItemUUIDs
{
	NSDictionary *existingItems = [store UUIDsAndStoreItemsForCommit: baseCommit];
	
	return [NSSet setWithArray: [[existingItems allKeys] arrayByAddingObjectsFromArray: [insertedOrUpdatedItems allKeys]]];
}
- (NSSet *)allItems
{
	NSMutableSet *result = [NSMutableSet set];
	for (ETUUID *uuid in [self allItemUUIDs])
	{
		[result addObject: [self storeItemForUUID: uuid]];
	}
	return result;
}

- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID
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

- (NSSet *) allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	NSMutableSet *result = [NSMutableSet set];
	
	COStoreItem *item = [self storeItemForUUID: aUUID];
	for (NSString *key in [item attributeNames])
	{
		NSDictionary *type = [item typeForAttribute: key];
		if ([[type objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
		{		
			for (ETUUID *embedded in [item allObjectsForAttribute: key])
			{
				[result addObject: embedded];
				[result unionSet: [self allEmbeddedObjectUUIDsForUUID: embedded]];
			}
		}
	}
	return result;
}

- (NSSet *) allEmbeddedObjectUUIDsForUUIDInclusive: (ETUUID*) aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	return [[self allEmbeddedObjectUUIDsForUUID: aUUID] setByAddingObject: aUUID];
}

- (NSSet *) allEmbeddedItemsForUUIDInclusive: (ETUUID*) aUUID
{
	NSSet *uuids = [self allEmbeddedObjectUUIDsForUUIDInclusive: aUUID];
	NSMutableSet *result = [NSMutableSet setWithCapacity: [uuids count]];
	for (ETUUID *uuid in uuids)
	{
		[result addObject: [self storeItemForUUID: uuid]];
	}
	return result;
}

- (void) insertOrUpdateItems: (NSSet *)items
	   newRootEmbeddedObject: (ETUUID*)aRoot
{
	NILARG_EXCEPTION_TEST(items);
	NILARG_EXCEPTION_TEST(aRoot);
	
	assert([items isKindOfClass: [NSSet class]]);
	
	ASSIGN(rootItem, aRoot);
	
	for (COStoreItem *item in items)
	{
		[insertedOrUpdatedItems setObject: item forKey: [item UUID]];
	}
	
	// FIXME: validation
}

- (void) insertOrUpdateItems: (NSSet *)items
{
	[self insertOrUpdateItems: items
		newRootEmbeddedObject: rootItem];
}

@end
