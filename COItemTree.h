#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;

/**
 * Immutable.
 */
@interface COItemTree : NSObject <NSCopying>
{
    COUUID *rootItemUUID_;
    NSDictionary *itemForUUID_;
}

/**
 * Caller may provide extra items, they will be ignored.
 */
+ (COItemTree *) treeWithItems: (NSArray *)items rootItemUUID: (COUUID *)aUUID;

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root;

- (COUUID *) rootItemUUID;
- (COItem *) itemForUUID: (COUUID *)aUUID;
/**
 * O(N); performs a DFS. TODO: Move DFS to -init
 */
- (NSArray *) itemUUIDs;

- (COItemTree *) itemTreeWithNameMapping: (NSDictionary *)aMapping;

@end
