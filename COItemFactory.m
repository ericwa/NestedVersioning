#import "COItemFactory.h"


@implementation COItemFactory

- (ETUUID *) copyEmbeddedObject: (ETUUID *)src
					fromContext: (id<COEditingContext>)srcCtx;
					insertInto: (ETUUID *)dest
					inContext: (id<COEditingContext>)destCtx
{
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

	
	COStoreItem *dest = [self storeItemForUUID: anObject];
	
	assert([[dest attributeNames] containsObject: attribute]);
	assert([[[dest typeForAttribute: attribute] objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind]);
	assert([[[dest typeForAttribute: attribute] objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem]);
	
	// FIXME: THis should be a UUID->COStoreItem dictionary
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
}


/* @taskunit persistent roots (TODO: move to class?) */

- (ETUUID *) newPersistentRootAtItemPath: (COItemPath*)aPath
{
	COStoreItem *branch = [COStoreItem item];
	COStoreItem *root = [COStoreItem item];
	
	[root setValue: S([branch UUID])
	  forAttribute: @"branches"
			  type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[root setValue: [COPath pathWithPathComponent:[branch UUID]]
	  forAttribute: @"currentBranch"
			  type: COPrimitiveType(kCOPrimitiveTypePath)];
	
	// FIXME: insert
	
	return [root UUID];
}

- (NSSet *) branchesOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *root = [self storeItemForUUID: aRoot];
	NSSet *set = [root valueForAttribute: @"branches"];
	
	assert([set isKindOfClass: [NSSet class]]);
	assert(![set isKindOfClass: [NSCountedSet class]]);
	
	return set;
}
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *root = [self storeItemForUUID: aRoot];
	COPath *path = [root valueForAttribute: @"currentBranch"];
	
	assert([path isKindOfClass: [COPath class]]);
	// FIXME: check it is a single-element path
	
	return [path lastPathComponent];	
}
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aRoot
{
	COStoreItem *root = [self storeItemForUUID: aRoot];
	[root setValue: [COPath pathWithPathComponent: aBranch]
	  forAttribute: @"currentBranch"
			  type: COPrimitiveType(kCOPrimitiveTypePath)];
	
	// FIXME: insert
}


- (void) setTrackRemoteBranchOrRoot: (COPath*)aPath
						  forBranch: (ETUUID*)aBranch
{
	COStoreItem *branch = [self storeItemForUUID: aBranch];
	
	[branch setValue: [COPath pathWithPathComponent: aBranch]
		forAttribute: @"tracking"
				type: COPrimitiveType(kCOPrimitiveTypePath)];
	
	// FIXME: insert
	
}

- (void) setTrackVersion: (ETUUID*)aVersion
			   forBranch: (ETUUID*)aBranch
{
	COStoreItem *branch = [self storeItemForUUID: aBranch];
	
	[branch setValue: aVersion
		forAttribute: @"tracking"
				type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];
	
	// FIXME: insert
	
}

- (void) undoPersistentRoot: (ETUUID*)aRoot
{
	/*
	- to undo:
	a) look up the version that "tracking" points to
	b) get its parent (if it has none, can't undo)
					   c) set "tracking" to the parent, without modifying tip
					   
*/					   
}
- (void) redoPersistentRoot: (ETUUID*)aRoot
{
	/*
	- to redo:
	X = "tip"
	if (X == "tracking") fail ("can't redo")
		while (1) {
			if (X.parent == "tracking") {
				"tracking" = X;
				finshed;
			}
			X = X.parent;
		}
	
	**/
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
 COStoreItem *item = [aCtxt storeItemForUUID: uuid];
 
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
 COStoreItem *itemCopy = [[self storeItemForUUID: sourceUUID] mutableCopy];
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
