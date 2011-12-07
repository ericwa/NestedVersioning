#import <Foundation/Foundation.h>
#import "ETUUID.h"
#import "COType.h"

/**
 * immutable object with only uuid and primitive type
 * values (no object tree) - a DB row
 */
@interface COItem : NSObject
{
	@private
	ETUUID *uuid;
	NSDictionary *types;
	NSDictionary *values;
}


- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * init with a new UUID
 */
- (id) init;

/**
 * new item with new UIID
 */
+ (COItem *) item;

- (ETUUID *)UUID;
- (void) setUUID: (ETUUID *)aUUID;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;
- (id) valueForAttribute: (NSString*)anAttribute;

/** @taskunit plist import/export */

- (id)plist;
- (id)initWithPlist: (id)aPlist;

/** @taskunit convenience */

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute;

// allows treating primitive or container, unordered or ordered as NSArray
- (NSArray*) allObjectsForAttribute: (NSString*)attribute;

- (id)copyWithZone:(NSZone *)zone;


@end
