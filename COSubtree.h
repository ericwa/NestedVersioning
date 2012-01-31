#import <Foundation/Foundation.h>

#import "COItem.h"
#import "ETUUID.h"

@class COSubtreeCopy;
@class COItemPath;

@interface COSubtree : NSObject <NSCopying>
{
	@private
	COMutableItem *root;
	NSMutableDictionary *embeddedSubtrees;
	COSubtree *parent;
}

/* @taskunit Creation */

- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * init with a new UUID
 */
- (id) init;

/**
 * new item with new UIID
 */
+ (COSubtree *)subtree;

/**
 * @returns a mutable copy
 */
- (id)copyWithZone:(NSZone *)zone;

/**
 * @returns a mutable copy with all items in the tree renamed.
 *
 * Implemented in terms of subtreeCopyWithNameMapping:
 */
- (COSubtreeCopy *)subtreeCopyRenamingAllItems;

/**
 * @returns a mutable copy with items specified in the mapping
 * dictionary renamed to the value specified in the dictionary,
 * and all other items keep their original names.
 *
 * Any items within receiver which have path attributes
 * pointing to items within the receiver will be updated to reflect
 * the new names.
 */
- (COSubtreeCopy *)subtreeCopyWithNameMapping: (NSDictionary *)aMapping;



/* @taskunit Access to the tree stucture  */



/**
 * @returns nil if the receiver has no parent.
 * Otherwise, the item tree node in which the receiver is embedded.
 */
- (COSubtree *) parent;

/**
 * Returns the root of the item tree
 */
- (COSubtree *) root;



/* @taskunit Access to the receiver's item */



- (ETUUID *)UUID;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;

/**
 * @returns the value for the given
 * attribute, with the special case of embedded item
 * UUIDs are returned as COSubtree objects
 */
- (id) valueForAttribute: (NSString*)anAttribute;

- (void) setPrimitiveValue: (id)aValue
			  forAttribute: (NSString*)anAttribute
					  type: (COType *)aType;



- (void)removeValueForAttribute: (NSString*)anAttribute;

- (NSSet *)embeddedItemTreeNodeUUIDs;
- (NSArray *)embeddedSubtrees;

/** @taskunit I/O */

- (NSSet*) allContainedStoreItems;
- (NSSet*) allContainedStoreItemUUIDs;

/** @taskunit Add/Delete/Move Operations */

/**
 * Searches the receiver for the subtree with the givent UUID.
 * Returns nil if not present
 */
- (COSubtree *) subtreeWithUUID: (ETUUID *)aUUID;

- (COItemPath *) itemPathOfSubtreeWithUUID: (ETUUID *)aUUID;

/**
 * Inserts the given subtree at the given item path.
 * The provided subtree is removed from its parent, if it has one.
 * i.e. [aSubtree parent] is mutated by the method call!
 *
 * Works regardless of whether aSubtree is a descendant of
 * [self parent].
 */
- (void) addSubtree: (COSubtree *)aSubtree
		 atItemPath: (COItemPath *)aPath;

/**
 * Removes a subtree (regardless of where in the receiver or the receiver's children
 * it is located.) Throws an exception if the guven UUID is not present in the receiver.
 */
- (void) removeSubtreeWithUUID: (ETUUID *)aUUID;

- (void) moveSubtreeWithUUID: (ETUUID *)aUUID
				  toItemPath: (COItemPath *)aPath;

@end

/**
 * Convenience methods for interacting with the default
 * "contents" set attribute
 */
@interface COSubtree (ContentsProperty)

/**
 * See comments on -addSubtree:atItemPath:
 */
- (void) addTree: (COSubtree *)aValue;

/**
 * @returns a set of COSubtree
 */
- (NSSet*) contents;

@end