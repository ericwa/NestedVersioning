#import "COPersistentRootEditingContext.h"
#import "Common.h"

@implementation COPersistentRootEditingContext

- (id)init
{
    SUPERINIT;
    
	insertedOrUpdatedItems = [[NSMutableSet alloc] init];
	deletedItems = [[NSMutableSet alloc] init];
	
    return self;
}

- (void) commit
{
}

- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID
{
	assert([aUUID isKindOfClass: [ETUUID class]]);
	
	COStoreItem *result = [sc storeItemForUUID: aUUID atVersion: baseCommit];
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
	assert([insertedOrUpdatedItems objectForKey: [anItem UUID]] == nil);
	assert([[anItem	UUID] isKindOfClass: [ETUUID class]]);
	[insertedOrUpdatedItems setObject: anItem forKey: [anItem UUID]];
}
- (void) updateItem: (COStoreItem *)anEditedItem
{
	assert([insertedOrUpdatedItems objectForKey: [anEditedItem UUID]] != nil);
	assert([[anEditedItem UUID] isKindOfClass: [ETUUID class]]);
	[insertedOrUpdatedItems setObject: anEditedItem forKey: [anEditedItem UUID]];
}
- (void) deleteItemWithUUID: (ETUUID*)itemUUID
{
	assert([itemUUID isKindOfClass: [ETUUID class]]);
	[deletedItems addObject: itemUUID];
}

@end
