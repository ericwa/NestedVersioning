#import <Foundation/Foundation.h>

#import "COItem.h"
#import "ETUUID.h"

@class COSubtreeCopy;

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

/** @taskunit convenience */

- (void) addTree: (COSubtree *)aValue
 forSetAttribute: (NSString*)anAttribute;

- (void) removeTree: (COSubtree *)aValue
 forSetAttribute: (NSString*)anAttribute;


/**
 * adds the given tree to the default @"contents" attribute
 */
- (void) addTree: (COSubtree *)aValue;
- (void) removeTree: (COSubtree *)aValue;
- (NSSet*)contents;



@end
