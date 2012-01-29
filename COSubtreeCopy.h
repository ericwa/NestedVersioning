#import <Foundation/Foundation.h>

@class ETUUID;
@class COSubtree;

@interface COSubtreeCopy : NSObject
{
	COSubtree *subtree;
	NSDictionary *mappingDictionary;
}

- (COSubtree *) subtree;
- (ETUUID *) replacementUUIDForUUID: (ETUUID*)aUUID;

@end


@interface COSubtreeCopy (Private)

+ (COSubtreeCopy *) subtreeCopyWithSubtree: (COSubtree*)aSubtree
						 mappingDictionary: (NSDictionary *)aDict;

@end