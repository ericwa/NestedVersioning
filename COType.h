#import <Foundation/Foundation.h>

/**
 * Every key/value pair of a COItem has a COType associated with it 
 * specifying what values are allowed. This creates a lightweight
 * schema/metamodel.
 *
 * The COType class provides a central place to put various bits 
 * of code such as:
 *  - validation of ObjC objects against the schema
 *  - plist import/export of ObjC objects of a known COType
 *  - diff of a pair of ObjC objects of a known COType
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
+ (COType *) uniqueArrayWithPrimitiveType: (COType *)aType;

/**
 * Creates a bag (a.k.a multiset) type. Can not be used with
 * [COType embeddedItemType] - an embedded item can be embedded
 * in only one place.
 */
+ (COType *) bagWithPrimitiveType: (COType *)aType;

/** Can not be used with
* [COType embeddedItemType] - an embedded item can be embedded
* in only one place.
*/
+ (COType *) arrayWithPrimitiveType: (COType *)aType;



- (BOOL) isMultivalued;
- (BOOL) isPrimitive;

/**
 * Throws an exception if the receiver is not multivalued
 */
- (BOOL) isOrdered;

/**
 * Throws an exception if the receiver is not multivalued.
 * 
 * @returns YES if the receiver can hold only one copy of a
 * value (i.e it is a set or "unique array")
 */
- (BOOL) isUnique;

/**
 * For primitive types, returns self.
 * For multivalued types, returns the type of objects in the multivalue
 */
- (COType *) primitiveType;

/**
 * @returns YES if the given ObjC value conforms to the receiver's type
 */
- (BOOL) validateValue: (id)aValue;


/** @taskunit String Import/Export */

/**
 * @returns a string identifier which can be used to recreate
 * the type with +typeWithString:
 */
- (NSString *) stringValue;
+ (COType*) typeWithString: (NSString *)aTypeString;

- (NSString *) description;

- (BOOL) isEqual: (id)object;


/** @taskunit NSCopying protocol */

/**
 * Since the receiver is immutable this just returns [self retain];
 */
- (id) copyWithZone: (NSZone *)zone;

@end
