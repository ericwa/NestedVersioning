#import <Foundation/Foundation.h>
#import "ETUUID.h"

// types are stored in dictionaries. they can either be primitive or container.
// all types must have kCOTypeKind set to kCOPrimitiveTypeKind or kCOContainerTypeKind.

NSString * const kCOTypeKind;
NSString * const kCOPrimitiveTypeKind;
NSString * const kCOContainerTypeKind;

// all types must have kCOPrimitiveType set to one of the types below.
// note that the things in a container must all be of the same type

NSString * const kCOPrimitiveType;
NSString * const kCOPrimitiveTypeInt64;
NSString * const kCOPrimitiveTypeDouble;
NSString * const kCOPrimitiveTypeString;
NSString * const kCOPrimitiveTypeFullTextIndexableString; 
NSString * const kCOPrimitiveTypeBlob;
NSString * const kCOPrimitiveTypeCommitUUID; // just a version uuid. prevents version from being GC'ed.

// this division of 3 reference types was borrowed from WinFS...


// doesn't prevent destination from being GC'ed.
// not copied when parent is copied.
// used for:
//   - link from document to tag objects in same or different persistent root
//   - link from photo album to photos in same or different persistent root
NSString * const kCOPrimitiveTypePath;

// only for objects in the same persistent root.
// within a persistent root, we will enforce that the embedded object has
// only one parent;
NSString * const kCOPrimitiveTypeEmbeddedItem; 

// if a type is a container type, it must have these two values set to either YES or NO
// to specify the type of container.

// NOTE: these will only really be used during merging and validation.
// not sure if it would make sense to allow setting user-defined attributes/extensions
// to types insteaad of hardcoding these

// NOTE: a container of kCOPrimitiveTypeEmbeddedItem can not have kCOContainerAllowsDuplicates

NSString * const kCOContainerOrdered;
NSString * const kCOContainerAllowsDuplicates;


// Convenience type constructors

NSDictionary *COBagContainerType(NSString *aPrimitiveType); // unordered, duplicates allowed. aka multiset. (NSCountedSet)
NSDictionary *COArrayContainerType(NSString *aPrimitiveType); // ordered, duplicates allowed. (NSArray)
NSDictionary *COSetContainerType(NSString *aPrimitiveType); // unordered, no duplicates. (NSSet)

NSDictionary *COPrimitiveType(NSString *aPrimitiveType);


/**
examples of type dictionaries:
 
 { kCOTypeKind : kCOPrimitiveTypeKind;
   kCOPrimitiveType : kCOPrimitiveTypeInt64 }
 
 { kCOTypeKind : kCOContainerTypeKind;
   kCOPrimitiveType : kCOPrimitiveTypeHoldingPath;
   kCOContainerOrdered : YES;
   kCOContainerAllowsDuplicates : NO } 
 
ObjC values for types:
 
kCOPrimitiveTypeInt64: NSNumber containing longLong
kCOPrimitiveTypeDouble: NSNumber containing double
kCOPrimitiveTypeString: NSString
kCOPrimitiveTypeBlob: NSData
kCOPrimitiveTypeCommitUUID: ETUUID

kCOPrimitiveTypeReferencePath: COPath
kCOPrimitiveTypeHoldingPath: COPath
kCOPrimitiveTypeEmbeddedObject: ETUUID
for containers:
 
kCOContainerOrdered = NO, kCOContainerAllowsDuplicates = NO: NSSet
kCOContainerOrdered = NO, kCOContainerAllowsDuplicates = YES: NSCountedSet 
kCOContainerOrdered = YES, kCOContainerAllowsDuplicates = NO: NSArray
kCOContainerOrdered = YES, kCOContainerAllowsDuplicates = YES: NSArray 
 
*/


/**
 * this class is the model object for "embedded objects".
 * 
 * currently it supports reading and writing embededd objects
 * to a simple plist format for debugging.
 * 
 * it will be changed to write the object to the sqlite db
 * at some point.
 */
@interface COStoreItem : NSObject <NSCopying>
{
@private
	ETUUID *uuid;
	NSMutableDictionary *types;
	NSMutableDictionary *values;
}

- (id) initWithUUID: (ETUUID*)aUUID;

/**
 * init with a new UUID
 */
- (id) init;

/**
 * new item with new UIID
 */
+ (COStoreItem *) item;


- (ETUUID *)UUID;
- (void) setUUID: (ETUUID *)aUUID;

- (NSArray *) attributeNames;

- (NSDictionary *) typeForAttribute: (NSString *)anAttribute;
- (id) valueForAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (NSDictionary*)aType;

/** @taskunit plist import/export */

- (id)plist;
- (id)initWithPlist: (id)aPlist;

/** @taskunit convenience */

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute;

// allows treating primitive or container, unordered or ordered as NSArray
- (NSArray*) allObjectsForAttribute: (NSString*)attribute;

/**
 * @returns a mutable copy
 */
- (id)copyWithZone:(NSZone *)zone;

@end
