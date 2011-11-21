#import "COPersistentRootEditingContext.h"
#import "Common.h"

@implementation COPersistentRootEditingContext

- (id)init
{
    SUPERINIT;
    
	insertedOrUpdatedItems = [[NSMutableDictionary alloc] init];
	deletedItems = [[NSMutableSet alloc] init];
	
    return self;
}

- (void)dealloc
{
	[insertedOrUpdatedItems release];
	[deletedItems release];
	[super dealloc];
}


- (void) commit
{
	NSDictionary *baseUUIDsAndItems = [store UUIDsAndStoreItemsForCommit: baseCommit];
	
	NSSet *initialUUIDs = [NSSet setWithArray: [baseUUIDsAndItems allKeys]];
	NSSet *insertedOrUpdatedUUIDs = [NSSet setWithArray: [insertedOrUpdatedUUIDs allKeys]];
	
	assert(![insertedOrUpdatedUUIDs intersectsSet: deletedItems]);
	
	// calculate final uuid set
	NSMutableSet *finalUUIDSet = [NSMutableSet set];
	{
		[finalUUIDSet unionSet: initialUUIDs];
		[finalUUIDSet unionSet: insertedOrUpdatedUUIDs];
		[finalUUIDSet minusSet: deletedItems];
	}
	
	// set up the commit dictionary
	NSMutableDictionary *uuidsanditems = [NSMutableDictionary dictionary];
	{
		for (ETUUID *uuid in finalUUIDSet)
		{
			COStoreItem *item;
			
			item = [insertedOrUpdatedItems objectForKey: uuid];
			if (item == nil)
			{
				// the object wasn't updated, so just take the old value.
				item = [baseUUIDsAndItems objectForKey: uuid]; 
			}
			
			[uuidsanditems setObject: item
							  forKey: uuid];
		}
	}
	
	// FIXME
	NSDictionary *md = [NSDictionary dictionaryWithObjectsAndKeys: @"today", @"date", nil];
	
	ETUUID *uuid = [store addCommitWithParent: baseCommit
									 metadata: md
						   UUIDsAndStoreItems: uuidsanditems];
	
	assert(uuid != nil);
	
	// FIXME
	
	ASSIGN(baseCommit, uuid);
	[deletedItems removeAllObjects];
	[insertedOrUpdatedItems removeAllObjects];
}


- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID
{
	assert([aUUID isKindOfClass: [ETUUID class]]);
	
	COStoreItem *result = [store storeItemForUUID: aUUID atVersion: baseCommit];
	COStoreItem *localResult = [insertedOrUpdatedItems objectForKey: aUUID];
	
	assert(result != nil);
	
	if (localResult != nil)
	{
		NSLog(@"overriding %@ with %@", result, localResult);
		result = localResult;
	}
	
	return result;
}

- (void) insertItem: (COStoreItem *)anItem
{
	ETUUID *uuid = [anItem UUID];
	if ([deletedItems containsObject: uuid])
	{
		[deletedItems removeObject: uuid];
	}
	
	assert([insertedOrUpdatedItems objectForKey: uuid] == nil);
	assert([uuid isKindOfClass: [ETUUID class]]);
	
	[insertedOrUpdatedItems setObject: anItem forKey: uuid];
}
- (void) updateItem: (COStoreItem *)anEditedItem
{
	ETUUID *uuid = [anEditedItem UUID];
	assert(![deletedItems containsObject: uuid]);
	assert([insertedOrUpdatedItems objectForKey: uuid] != nil);
	assert([uuid isKindOfClass: [ETUUID class]]);
	
	[insertedOrUpdatedItems setObject: anEditedItem forKey: uuid];
}
- (void) deleteItemWithUUID: (ETUUID*)itemUUID
{
	if (nil != [insertedOrUpdatedItems objectForKey: itemUUID])
	{
		[insertedOrUpdatedItems removeObjectForKey: itemUUID];
	}
	
	assert([itemUUID isKindOfClass: [ETUUID class]]);
	
	[deletedItems addObject: itemUUID];
}

@end
