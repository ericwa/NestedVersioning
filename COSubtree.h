#import <Foundation/Foundation.h>

#import "COItem.h"
#import "ETUUID.h"


@interface COSubtree : NSObject <NSCopying>
{
	@private
	COMutableItem *root;
	NSMutableDictionary *embeddedItemTreeNodes;
	COSubtree *parent;
}

- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * init with a new UUID
 */
- (id) init;

/**
 * new item with new UIID
 */
+ (COSubtree *)subtree;

- (ETUUID *)UUID;

/**
 * @returns nil if the receiver has no parent.
 * Otherwise, the item tree node in which the receiver is embedded.
 */
- (COSubtree *) parent;

/**
 * Returns the root of the item tree
 */
- (COSubtree *) root;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;
- (id) valueForAttribute: (NSString*)anAttribute;

- (void) setPrimitiveValue: (id)aValue
			  forAttribute: (NSString*)anAttribute
					  type: (COType *)aType;




- (void)removeValueForAttribute: (NSString*)anAttribute;

- (NSSet *)embeddedItemTreeNodeUUIDs;
- (NSArray *)embeddedItemTreeNodes;

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

/**
 * @returns a mutable copy
 */
- (id)copyWithZone:(NSZone *)zone;

@end
