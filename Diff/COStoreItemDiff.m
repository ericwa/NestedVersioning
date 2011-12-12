#import "COStoreItemDiff.h"
#import "COMacros.h"

// operation classes

@interface COStoreItemDiffOperation : NSObject
{
	NSString *attribute;
	COType *type;
}
@end


@interface COStoreItemDiffOperationInsertAttribute : COStoreItemDiffOperation 
{
	id value;
}

@end



@interface COStoreItemDiffOperationDeleteAttribute : COStoreItemDiffOperation
@end



@interface COStoreItemDiffOperationModifyAttribute : COStoreItemDiffOperation
{
}

@end

// operation implementations

@implementation COStoreItemDiffOperation

@end


@implementation COStoreItemDiffOperationInsertAttribute
@end



@implementation COStoreItemDiffOperationDeleteAttribute
@end



@implementation COStoreItemDiffOperationModifyAttribute

@end


// Main implementation

@implementation COStoreItemDiff

+ (COStoreItemDiff *)diffItem: (COStoreItem *)itemA
					 withItem: (COStoreItem *)itemB
{
	NILARG_EXCEPTION_TEST(itemA);
	NILARG_EXCEPTION_TEST(itemB);
	
	if (![[itemA UUID] isEqual: [itemB UUID]])
	{
		NSLog(@"Warning, diffing items with different UUIDs (%@, %@)",
				[itemA UUID], [itemB UUID]);
	}
	
	NSMutableSet *removedAttrs = [NSMutableSet setWithArray: [itemA attributeNames]];
	[removedAttrs minusSet: [NSSet setWithArray: [itemB attributeNames]]];
	
	NSMutableSet *addedAttrs = [NSMutableSet setWithArray: [itemB attributeNames]];
	[addedAttrs minusSet: [NSSet setWithArray: [itemA attributeNames]]];
	
	
	return nil;
}

- (COStoreItem *)itemWithDiffAppliedTo: (COStoreItem *)anItem
{
	return nil;
}

@end
