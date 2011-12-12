#import <Foundation/Foundation.h>
#import "COStoreItem.h"

@interface COStoreItemDiff : NSObject
{
	NSMutableSet *edits;
}

+ (COStoreItemDiff *)diffItem: (COStoreItem *)itemA
					 withItem: (COStoreItem *)itemB;

- (COStoreItem *)itemWithDiffAppliedTo: (COStoreItem *)anItem;

@end
