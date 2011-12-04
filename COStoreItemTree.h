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

/** @taskunit convenience */

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute
			  type: (NSDictionary*)aType;

/**
 * @returns a mutable copy
 */
- (id)copyWithZone:(NSZone *)zone;

@end
