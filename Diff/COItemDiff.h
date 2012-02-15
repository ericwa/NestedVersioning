#import <Foundation/Foundation.h>
#import "COItem.h"

/**
 * This produces a diff object which transforms one
 * item into another; preserving as much as possible.
 *
 * Item diffs can be in a conflicted state when
 * two are merged that insert the same embedded item UUID
 * in two different places.
 */
@interface COItemDiff : NSObject
{
	NSSet *edits;
}

+ (COItemDiff *)diffItem: (COItem *)itemA
					 withItem: (COItem *)itemB;

- (COItem *)itemWithDiffAppliedTo: (COItem *)anItem;

- (NSUInteger) editCount;

- (COItemDiff *)itemDiffByMergingWithDiff: (COItemDiff *)other;

@end
