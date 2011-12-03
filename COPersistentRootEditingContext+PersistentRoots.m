#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "Common.h"
#import "COStoreItem.h"
#import "ETUUID.h"

@implementation COPersistentRootEditingContext (PersistentRoots)

- (ETUUID *)createAndInsertAsRootItemNewPersistentRootWithRootItem: (COStoreItem *)anItem
{
	ETUUID *nestedDocumentInitialVersion = [store addCommitWithParent: nil
															 metadata: nil
												   UUIDsAndStoreItems: D(anItem, [anItem UUID])
															 rootItem: [anItem UUID]];
	assert(nestedDocumentInitialVersion != nil);
	
	
	COStoreItem *i1 = [COStoreItem item];
	COStoreItem *i2 = [COStoreItem item];
	
	[i1 setValue: @"persistentRoot"
	forAttribute: @"type"
			type: COPrimitiveType(kCOPrimitiveTypeString)];	
	[i1 setValue: @"test document"
	forAttribute: @"name"
			type: COPrimitiveType(kCOPrimitiveTypeString)];
	[i1 setValue: [COPath pathWithPathComponent: [i2 UUID]]
	forAttribute: @"currentBranch"
			type: COPrimitiveType(kCOPrimitiveTypePath)];	
	[i1 setValue: S([i2 UUID])
	forAttribute: @"contents"
			type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[i2 setValue: @"branch"
	forAttribute: @"type"
			type: COPrimitiveType(kCOPrimitiveTypeString)];	
	[i2 setValue: nestedDocumentInitialVersion
	forAttribute: @"tracking"
			type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];		
	
	[self _insertOrUpdateItems: S(i1, i2)
		 newRootEmbeddedObject: [i1 UUID]];

	return [i1 UUID];
}

@end
