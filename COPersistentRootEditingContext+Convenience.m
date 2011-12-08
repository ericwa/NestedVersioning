#import "COPersistentRootEditingContext+Convenience.h"
#import "Common.h"
#import "COStoreItem.h"
#import "ETUUID.h"
#import "COType.h"

@implementation COPersistentRootEditingContext (Convenience)

- (void) insertValue: (id)aValue
	   primitiveType: (COType *)aPrimitiveType
	  inSetAttribute: (NSString*)anAttribute
			ofObject: (ETUUID*)aDest
{
	NILARG_EXCEPTION_TEST(aValue);
	NILARG_EXCEPTION_TEST(aPrimitiveType);
	NILARG_EXCEPTION_TEST(anAttribute);
	NILARG_EXCEPTION_TEST(aDest);
	
	COStoreItem *destItem = [self _storeItemForUUID: aDest];
	assert(destItem != nil);
	
	COType *type = [destItem typeForAttribute: anAttribute];
	NSSet *destContents = [destItem valueForAttribute: anAttribute];
	if (type == nil && destContents == nil)
	{
		destContents = S(aValue);
	}
	else
	{
		assert([type isMultivalued]);
		assert(![type isOrdered]);
		assert([type isUnique]);
		assert([aPrimitiveType isEqual: [type primitiveType]]);
		
		assert([destContents isKindOfClass: [NSSet class]]);
		destContents = [destContents setByAddingObject: aValue];
	}
	
	[destItem setValue: destContents
		  forAttribute: @"contents"
				  type: [COType setWithPrimitiveType: aPrimitiveType]];
	
	[self _insertOrUpdateItems: S(destItem)];	
}

- (ETUUID *) insertTree: (COStoreItemTree*)aTree
		inContainer: (ETUUID*)aContainer
{
	[self insertValue: [aTree UUID]
		primitiveType: [COType embeddedItemType]
	   inSetAttribute: @"contents"
			 ofObject: aContainer];
	
	[self _insertOrUpdateItems: [aTree allContainedStoreItems]];	
	return [aTree UUID];
}

@end