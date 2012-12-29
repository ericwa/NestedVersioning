#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;

/**
 * Immutable.
 */
@interface COItemTree : NSObject <NSCopying>
{
    COUUID *root_;
    NSDictionary *itemForUUID_;
}

+ (COItemTree *) treeWithItems: (NSArray *)items rootUUID: (COUUID *)aUUID;

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
                      root: (COUUID *)root;

- (COUUID *) root;
- (COItem *) itemForUUID: (COUUID *)aUUID;
- (NSArray *) objectUUIDs;

- (COItemTree *) objectTreeWithNameMapping: (NSDictionary *)aMapping;

@end
