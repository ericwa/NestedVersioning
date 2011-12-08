#import <Foundation/Foundation.h>

/**
 * Immutable object representing a value type.
 */
@interface COType : NSObject <NSCopying>

+ (COType *) int64Type;
+ (COType *) doubleType;
+ (COType *) stringType;
+ (COType *) fullTextIndexableStringType;
+ (COType *) blobType;
+ (COType *) commitUUIDType;
+ (COType *) pathType;
+ (COType *) embeddedItemType;

+ (COType *) setWithPrimitiveType: (COType *)aType;
+ (COType *) bagWithPrimitiveType: (COType *)aType;
+ (COType *) arrayWithPrimitiveType: (COType *)aType;
+ (COType *) uniqueArrayWithPrimitiveType: (COType *)aType;

- (BOOL) isMultivalued;
- (BOOL) isPrimitive;

- (BOOL) validateValue: (id)aValue;

/** @taskunit String Import/Export */

- (NSString *) stringValue;
+ (COType*) typeWithString: (NSString *)aTypeString;

- (NSString *) description;

/** @taskunit NSCopying protocol */

- (id) copyWithZone:(NSZone *)zone;

@end
