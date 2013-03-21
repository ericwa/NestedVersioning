#import <Foundation/Foundation.h>

/**
 * Each key/value pair of a COItem has a COType associated with it.
 *
 * The type defines the set of permissible values which can be set for
 * that attribute, and possibly additional semantics of the value
 * which aren't captured by the Objective-C object alone - for example,
 * one value in a COItem might be an NSArray instance, but the corresponding
 * COType might additionally indicate that the array contains embedded item
 * UUIDs, and the array has a restriction that its elements must be unique.
 *
 * COType is designed with a few things in mind:
 *  - being able to store the values of a COItem in an SQL database,
 *    so the primitive types map cleanly to SQL types.
 *  - validation of ObjC objects against the schema
 *  - plist import/export of ObjC objects of a known COType
 */
@interface COType : NSObject <NSCopying>

+ (COType *) int64Type;
+ (COType *) doubleType;
+ (COType *) stringType;
+ (COType *) blobType;
+ (COType *) pathType;
+ (COType *) embeddedItemType;

+ (COType *) commitUUIDType;
+ (COType *) attachmentType;
+ (COType *) referenceType;

- (COType *) setType;
- (COType *) arrayType;

- (COType *) namedType: (NSString *)aName;
- (COType *) storageType; // Type ignoring name

- (BOOL) isMultivalued;
- (BOOL) isPrimitive;

/**
 * Throws an exception if the receiver is not multivalued
 */
- (BOOL) isOrdered;

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

/**
 * @returns YES if the primitiveType of the receiver is equal to the argument
 * throws an exception if the argument is not a primitive type.
 */
- (BOOL) isPrimitiveTypeEqual: (id)object;


/** @taskunit NSCopying protocol */

/**
 * Since the receiver is immutable this just returns [self retain];
 */
- (id) copyWithZone: (NSZone *)zone;

@end
