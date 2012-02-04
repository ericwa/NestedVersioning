#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;

@interface COSubtreeDiff : NSObject
{
	ETUUID *root;
	NSMutableDictionary *itemDiffForUUID;
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b;

- (void) applyToSubtree: (COSubtree *)aSubtree;

@end
