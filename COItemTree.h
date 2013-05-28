#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;

/**
 * Protocol for a mutable item graph
 *
 * 3 options:
 *  1. All objects must have a composite relationship path to the root item
 *     (tree approach)
 *  2. Same as 1, but objects can have a chain of references from the tree
 *     (garbage-collected graph approach)
 *  3. Objects don't need a reference to stay alive (multiple roots approach)
 *
 * 1 seems unnecessairily restrictive.
 * 3 introduces an explicit "delete" operation. This will pollute diffs with
 *   "Delete index 3 of files" + "delete file a, b, c, d" when the set of files
 *   a,b,c,d is derived from "index 3". 
 * 2 seems to be the best option.
 *
 */
@protocol COItemGraph <NSObject>

- (COUUID *) rootItemUUID;
- (COItem *) itemForUUID: (COUUID *)aUUID;
- (NSArray *) itemUUIDs;
- (void) addItem: (COItem *)anItem;

@end

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
@interface COItemTree : NSObject <COItemGraph>
{
    COUUID *rootItemUUID_;
    NSMutableDictionary *itemForUUID_;
}

+ (COItemTree *)treeWithItemsRootFirst: (NSArray*)items;

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root;
- (id) initWithItems: (NSArray *)items
        rootItemUUID: (COUUID *)root;

- (COUUID *) rootItemUUID;
- (COItem *) itemForUUID: (COUUID *)aUUID;

- (NSArray *) itemUUIDs;

- (void) addItem: (COItem *)anItem;

@end
