#import "COItemFactory.h"
#import "COEditingContext.h"
#import "COItemPath.h"
#import "COPath.h"
#import "COPersistentRootEditingContext.h"
#import "COMacros.h"

@implementation COItemFactory

/**
 *
 * Needs to know where to insert the item.. not just UUID but attribute as well
 */
- (ETUUID *) copyEmbeddedObject: (ETUUID *)src
					fromContext: (id<COEditingContext>)srcCtx
					insertInto: (ETUUID *)dest
					inContext: (id<COEditingContext>)destCtx
{
#if 0
	// 1. if src is already in the destination context
	//    delete it and all its contents.
	// 2. S = the set of items in src which are already in destCtx
	//    (after executing step 1. normally it is an empty set)
	//    
	//    
	
	
	
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(aCtxt);
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(aCtxt);

	
	COMutableStoreItem *dest = [self storeItemForUUID: anObject];
	
	assert([[dest attributeNames] containsObject: attribute]);
	assert([[[dest typeForAttribute: attribute] objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind]);
	assert([[[dest typeForAttribute: attribute] objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem]);
	
	// FIXME: THis should be a UUID->COMutableStoreItem dictionary
	// so we guarantee that the set doesnt' contain multiple items with the same UUID.
	NSMutableSet *updatesAndInserts = [NSMutableSet set];
	[updatesAndInserts unionSet: [aCtxt allEmbeddedItemsForUUIDInclusive: aUUID]];
	
	// Not strictly necessary
	{		
		NSMutableSet *objectsToBeOverwrittenUUIDS = [NSMutableSet setWithSet: [self allItemUUIDs]];
		[objectsToBeOverwrittenUUIDS intersectSet: [aCtxt allEmbeddedObjectUUIDsForUUIDInclusive: aUUID]];
		NSLog(@"Overwriting %@ in copy", objectsToBeOverwrittenUUIDS);
	}
	
	// Insert the new UUID into the destination item.
	NSMutableArray *array = [NSMutableArray arrayWithArray: [dest valueForAttribute: attribute]];
	[array insertObject: aUUID atIndex: i];
	[dest setValue:array forAttribute: attribute];
	
	[updatesAndInserts addObject: dest];
	
	[self insertOrUpdateItems: updatesAndInserts];
#endif
}


- (void) copyEmbeddedObject: (ETUUID*) aUUID
				fromContext: (COPersistentRootEditingContext*) aCtxt
	  toUnorderedCollection: (NSString*)attribute
				   inObject: (ETUUID*)anObject
{
	assert(0);
}


- (ETUUID *) copyEmbeddedObject: (ETUUID*) aUUID
						toIndex: (NSUInteger)i
				   ofCollection: (NSString*)attribute
					   inObject: (ETUUID*)anObject
{
	assert(0);
	return nil;
}

- (ETUUID *) copyEmbeddedObject: (ETUUID*) aUUID
		  toUnorderedCollection: (NSString*)attribute
					   inObject: (ETUUID*)anObject
{
	assert(0);
	return nil;
}


/*
 
 - (void) copyEmbeddedObject: (ETUUID*) aUUID
 fromContext: (COPersistentRootEditingContext*) aCtxt
 {
 NILARG_EXCEPTION_TEST(aUUID);
 NILARG_EXCEPTION_TEST(aCtxt);
 
 NSSet *uuids = [self allEmbeddedObjectUUIDsForUUIDInclusive: aUUID];
 for (ETUUID *uuid in uuids)
 {
 COMutableStoreItem *item = [aCtxt storeItemForUUID: uuid];
 
 // FIXME: This assumes that -insertItem doens't check that
 // kCOPrimitiveTypeEmbeddedItem constraints are enforced.
 // Assuming the source context was consistent, our context will
 // be consistent after this loop exits. Need to clarify the
 // guarantees that we can give about kCOPrimitiveTypeEmbeddedItem
 [self insertItem: item];
 }
 }
 
 - (ETUUID *) copyEmbeddedObject: (ETUUID *)aUUID
 {
 NILARG_EXCEPTION_TEST(aUUID);
 
 NSSet *sourceUUIDs = [self allEmbeddedObjectUUIDsForUUIDInclusive: aUUID];
 NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithCapacity: [sourceUUIDs count]];
 
 for (ETUUID *sourceUUID in sourceUUIDs)
 {
 [mapping setObject: [ETUUID UUID]
 forKey: sourceUUID];
 }
 
 for (ETUUID *sourceUUID in sourceUUIDs)
 {
 COMutableStoreItem *itemCopy = [[self storeItemForUUID: sourceUUID] mutableCopy];
 for (NSString *key in [itemCopy attributeNames])
 {
 // FIXME:
 // look up the value(s) for 'key' in 'mapping'; if found,
 // replace with the mapped value.
 }
 [self insertItem: itemCopy];
 [itemCopy release];
 }
 }
 */


@end
