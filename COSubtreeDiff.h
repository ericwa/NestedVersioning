#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;

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

@end
