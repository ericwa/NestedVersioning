#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "Common.h"
#import "COStoreItem.h"
#import "ETUUID.h"

@implementation COPersistentRootEditingContext (PersistentRoots)

- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COStoreItem *)anItem
										  inItemWithUUID: (ETUUID*)aDest
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
	
	// insert
	
	COStoreItem *destItem = [self _storeItemForUUID: aDest];
	assert(destItem != nil);
	
	NSSet *destContents = [destItem valueForAttribute: @"contents"];
	assert(destContents == nil);
	
	destContents = S([i1 UUID]);
	
	[destItem setValue: destContents
		  forAttribute: @"contents"
				  type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[self _insertOrUpdateItems: S(i1, i2, destItem)];

	return [i1 UUID];
}

@end
