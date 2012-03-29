#import <Foundation/Foundation.h>

@class COUUID;
@class COSubtree;

/**
 * Simple utility class, returned from -[COSubtree subtreeCopyRenamingAllItems],
 * used to provide both the subtree created by the copy operation, and a dictionary mapping the
 * old to new UUID's (so you given an item in the source tree, you can lookup
 * what it was renamed to in the copy).
 */
@interface COSubtreeCopy : NSObject
{
	COSubtree *subtree;
	NSDictionary *mappingDictionary;
}

- (COSubtree *) subtree;
- (COUUID *) replacementUUIDForUUID: (COUUID*)aUUID;

@end


@interface COSubtreeCopy (Private)

+ (COSubtreeCopy *) subtreeCopyWithSubtree: (COSubtree*)aSubtree
						 mappingDictionary: (NSDictionary *)aDict;

@end