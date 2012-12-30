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

+ (COItemTree *) treeWithItems: (NSArray *)items rootItemUUID: (COUUID *)aUUID;

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root;

- (COUUID *) rootItemUUID;
- (COItem *) itemForUUID: (COUUID *)aUUID;
- (NSArray *) itemUUIDs;

- (COItemTree *) itemTreeWithNameMapping: (NSDictionary *)aMapping;

@end
