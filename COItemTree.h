#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;
@class COItemTree;

/**
 * A partial item tree is just an immutable set of COItem objects along
 * with the UUID of the root object.
 *
 * However, there is no guarantee that the items form a complete tree,
 * or even that the item for the root UUID is in the set of items.
 * The user is expected to have the rest of the objects available to assemble
 * a complete tree. The COItemTree subclass, on the other hand, provides those guarantees.
 *
 * The intended use for COPartialItemTree is as a really simple
 * delta mechanism, so you can compute (COItemTree + COPartialItemTree) = a new COItemTree
 */
@interface COPartialItemTree : NSObject <NSCopying>
{
    COUUID *rootItemUUID_;
    NSDictionary *itemForUUID_;
}

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root;

+ (id) itemTreeWithItems: (NSArray *)items rootItemUUID: (COUUID *)aUUID;

- (COUUID *) rootItemUUID;
- (COItem *) itemForUUID: (COUUID *)aUUID;

- (NSArray *) itemUUIDs;

- (id) itemTreeByAddingItemTree: (COPartialItemTree *)partialTree;

- (id) itemTreeWithNameMapping: (NSDictionary *)aMapping;

- (COItemTree *) itemTree;

@end

@interface COItemTree : COPartialItemTree

@end
