#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;

/**
 * Concerns for COSubtreeDiff:
 * - conflicts arise when the same subtree is inserted in multiple places. These conflicts
 *   won't be captured by the COSequenceDiff, say.
 * - note that a _COSubtree_ cannot exist in an inconsistent state.
 */
@interface COSubtreeDiff : NSObject
{
	ETUUID *oldRoot;
	ETUUID *newRoot;
	NSMutableDictionary *itemDiffForUUID;  // ETUUID : COItemDiff
	NSMutableDictionary *insertedItemForUUID; // ETUUID : COItem
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b;

- (COSubtree *) subtreeWithDiffAppliedToSubtree: (COSubtree *)aSubtree;

- (COSubtreeDiff *)subtreeDiffByMergingWithDiff: (COSubtreeDiff *)other;

- (BOOL) hasConflicts;


@end
