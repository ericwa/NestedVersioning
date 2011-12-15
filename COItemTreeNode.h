#import <Foundation/Foundation.h>

#import "COItem.h"
#import "ETUUID.h"


@interface COItemTreeNode : NSObject <NSCopying>
{
	@private
	COMutableItem *root;
	NSMutableDictionary *embeddedItemTreeNodes;
	COItemTreeNode *parent;
}

- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * init with a new UUID
 */
- (id) init;

/**
 * new item with new UIID
 */
+ (COItemTreeNode *)itemTree;

- (ETUUID *)UUID;

/**
 * @returns nil if the receiver has no parent.
 * Otherwise, the item tree node in which the receiver is embedded.
 */
- (COItemTreeNode *) parent;

/**
 * Returns the root of the item tree
 */
- (COItemTreeNode *) root;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;
- (id) valueForAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType;

- (void)removeValueForAttribute: (NSString*)anAttribute;

/** @taskunit I/O */

- (NSSet*) allContainedStoreItems;
- (NSSet*) allContainedStoreItemUUIDs;

/** @taskunit convenience */

- (void) addTree: (COItemTreeNode *)aValue
 forSetAttribute: (NSString*)anAttribute;

- (void) removeTree: (COItemTreeNode *)aValue
 forSetAttribute: (NSString*)anAttribute;


/**
 * adds the given tree to the default @"contents" attribute
 */
- (void) addTree: (COItemTreeNode *)aValue;
- (void) removeTree: (COItemTreeNode *)aValue;
- (NSSet*)contents;

/**
 * @returns a mutable copy
 */
- (id)copyWithZone:(NSZone *)zone;

@end
