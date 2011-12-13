#import <Foundation/Foundation.h>
#import "COItem.h"

@interface COItemDiff : NSObject
{
	NSSet *edits;
}

+ (COItemDiff *)diffItem: (COItem *)itemA
					 withItem: (COItem *)itemB;

- (COItem *)itemWithDiffAppliedTo: (COItem *)anItem;

@end
