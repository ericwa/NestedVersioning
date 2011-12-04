#import <Foundation/Foundation.h>

#import "COStoreItem.h"
#import "ETUUID.h"

/**
 * note: items retrieved from an item tree should be copied before being modified
 */
@interface COStoreItemTree : NSObject <NSCopying>
{
	@private
	COStoreItem *root;
	NSMutableDictionary *items;
}

- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * init with a new UUID
 */
- (id) init;

/**
 * new item with new UIID
 */
+ (COStoreItemTree *)itemTree;

- (ETUUID *)UUID;

- (NSArray *) attributeNames;

- (NSDictionary *) typeForAttribute: (NSString *)anAttribute;
- (id) valueForAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (NSDictionary*)aType;

- (void)removeValueForAttribute: (NSString*)anAttribute;

/** @taskunit I/O */

- (NSSet*) allContainedStoreItems;

/** @taskunit convenience */

- (void) addTree: (COStoreItemTree *)aValue
 forSetAttribute: (NSString*)anAttribute;

/**
 * adds the given tree to the default @"contents" attribute
 */
- (void) addTree: (COStoreItemTree *)aValue;
- (void) removeTree: (COStoreItemTree *)aValue;
- (NSSet*)contents;

/**
 * @returns a mutable copy
 */
- (id)copyWithZone:(NSZone *)zone;

@end
