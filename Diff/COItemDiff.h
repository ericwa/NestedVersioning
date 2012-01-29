#import <Foundation/Foundation.h>
#import "COItem.h"

/**
 * This produces a diff object which transforms one
 * item into another; preserving as much as possible.
 */
@interface COItemDiff : NSObject
{
	NSSet *edits;
}

+ (COItemDiff *)diffItem: (COItem *)itemA
					 withItem: (COItem *)itemB;

- (COItem *)itemWithDiffAppliedTo: (COItem *)anItem;

- (NSUInteger) editCount;

@end
