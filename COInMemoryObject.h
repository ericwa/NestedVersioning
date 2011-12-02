#import <Foundation/Foundation.h>

#import "COStoreItem.h"

/**
 * This class is to make it easy to construct small
 * trees of objects (in COStoreItem format).
 *
 * e.g., the COItemFactory could return instances
 * of COInMemoryObject.
 */
@interface COInMemoryObject : NSObject
{
@private
	ETUUID *uuid;
	NSMutableDictionary *types;
	NSMutableDictionary *values;
}

- (id) initWithUUID: (ETUUID*)aUUID;
- (id) init;
+ (COInMemoryObject *) object;

- (ETUUID *)UUID;

/* @taskunit access */

- (NSArray *) attributeNames;
- (NSDictionary *) typeForAttribute: (NSString *)anAttribute;

/* @taskunit schema */

- (void) removeAttribute: (NSString *)anAttribute;
- (void) addAttribute: (NSString *)anAttribute type: (NSDictionary *)aType;

/* @taskunit values */

- (void) addValue: (id)anObject
	 forAttribute: (NSString *)anAttribute;

- (void) addValue: (id)anObject
		  atIndex: (NSUInteger)anIndex
	 forAttribute: (NSString *)anAttribute;

- (void) removeValue: (id)anObject
		forAttribute: (NSString *)anAttribute;

- (void) removeValue: (id)anObject
			 atIndex: (NSUInteger)anIndex
		forAttribute: (NSString *)anAttribute;

- (void) setValue: (id)anObject
	 forAttribute: (NSString *)anAttribute;

- (id) valueForAttribute: (NSString*)anAttribute;

@end
