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
	NSMutableDictionary *editForAttribute;
	// FIXME: temporary hack
	BOOL conflicting;
}

+ (COItemDiff *)diffItem: (COItem *)itemA
					 withItem: (COItem *)itemB;

- (COItem *)itemWithDiffAppliedTo: (COItem *)anItem;
- (void) applyTo: (COMutableItem*)aMutableItem;

- (NSUInteger) editCount;

- (COItemDiff *)itemDiffByMergingWithDiff: (COItemDiff *)other;

- (BOOL) hasConflicts;

@end
