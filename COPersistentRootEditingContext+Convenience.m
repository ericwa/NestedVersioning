#import "COPersistentRootEditingContext+Convenience.h"
#import "Common.h"
#import "COStoreItem.h"
#import "ETUUID.h"

@implementation COPersistentRootEditingContext (Convenience)

- (void) insertValue: (id)aValue
	   primitiveType: (NSString*)aPrimitiveType
	  inSetAttribute: (NSString*)anAttribute
			ofObject: (ETUUID*)aDest
{
	NILARG_EXCEPTION_TEST(aValue);
	NILARG_EXCEPTION_TEST(aPrimitiveType);
	NILARG_EXCEPTION_TEST(anAttribute);
	NILARG_EXCEPTION_TEST(aDest);
	
	COStoreItem *destItem = [self _storeItemForUUID: aDest];
	assert(destItem != nil);
	
	NSDictionary *type = [destItem typeForAttribute: anAttribute];
	NSSet *destContents = [destItem valueForAttribute: anAttribute];
	if (type == nil && destContents == nil)
	{
		destContents = S(aValue);
	}
	else
	{
		assert([kCOContainerTypeKind isEqual: [type objectForKey: kCOTypeKind]]);
		assert([[NSNumber numberWithBool: NO] isEqual: [type objectForKey: kCOContainerOrdered]]);
		assert([[NSNumber numberWithBool: NO] isEqual: [type objectForKey: kCOContainerAllowsDuplicates]]);
		assert([aPrimitiveType isEqual: [type objectForKey: kCOPrimitiveType]]);
		
		assert([destContents isKindOfClass: [NSSet class]]);
		destContents = [destContents setByAddingObject: aValue];
	}
	
	[destItem setValue: destContents
		  forAttribute: @"contents"
				  type: COSetContainerType(aPrimitiveType)];
	
	[self _insertOrUpdateItems: S(destItem)];	
}

@end