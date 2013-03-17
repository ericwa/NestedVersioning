#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;

/**
 * An item tree is just an immutable set of COItem objects along
 * with the UUID of the root object.
 *
 * However, there is no guarantee that the items form a complete tree,
 * or even that the item for the root UUID is in the set of items.
 *
 * The intended use for COItemTree is as a really simple
 * delta mechanism, so you can compute (COItemTree + COItemTree) = a new COItemTree
 */
@interface COItemTree : NSObject
{
    COUUID *rootItemUUID_;
    NSDictionary *itemForUUID_;
}

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root;

- (COUUID *) rootItemUUID;
- (COItem *) itemForUUID: (COUUID *)aUUID;

- (NSArray *) itemUUIDs;

@end
