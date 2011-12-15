#import <Foundation/Foundation.h>
#import "ETUUID.h"
#import "COType.h"

/**
 * this class is the model object for "embedded objects".
 * 
 * currently it supports reading and writing embededd objects
 * to a simple plist format for debugging.
 * 
 * it will be changed to write the object to the sqlite db
 * at some point.
 */
@interface COItem : NSObject <NSCopying, NSMutableCopying>
{
	ETUUID *uuid;
	NSDictionary *types;
	NSDictionary *values;
}

/**
 * designated initializer.
 */
- (id) initWithUUID: (ETUUID *)aUUID
 typesForAttributes: (NSDictionary *)typesForAttributes
valuesForAttributes: (NSDictionary *)valuesForAttributes;

+ (COItem *) itemWithTypesForAttributes: (NSDictionary *)typesForAttributes
						 valuesForAttributes: (NSDictionary *)valuesForAttributes;

- (ETUUID *) UUID;

- (NSArray *) attributeNames;

- (COType *) typeForAttribute: (NSString *)anAttribute;
- (id) valueForAttribute: (NSString*)anAttribute;

/** @taskunit plist import/export */

- (id)plist;
- (id)initWithPlist: (id)aPlist;

/** @taskunit convenience */

// allows treating primitive or container, unordered or ordered as NSArray
- (NSArray*) allObjectsForAttribute: (NSString*)attribute;

- (NSSet *) allEmbeddedItemUUIDs;

/** @taskunit NSCopying and NSMutableCopying */

- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;

@end



@interface COMutableItem : COItem
{
}

- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * new item with new UIID
 */
+ (COMutableItem *) item;

- (void) setUUID: (ETUUID *)aUUID;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (COType *)aType;

- (void)removeValueForAttribute: (NSString*)anAttribute;

/** @taskunit convenience */

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute;

- (id) copyWithZone:(NSZone *)zone;

@end

