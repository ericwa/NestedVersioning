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

NSString * const kCOPrimitiveTypeReferencePath;// doesn't prevent destination from being GC'ed. not copied when parent is copied
NSString * const kCOPrimitiveTypeHoldingPath; // prevents destination from being GC'ed.        copied when parent is copied
NSString * const kCOPrimitiveTypeEmbeddedItem; // only for objects in the same persistent root.
 											 	 // within a persistent root, we will enforce that the embedded object has
												 // only one parent;

// if a type is a container type, it must have these two values set to either YES or NO
// to specify the type of container.

// NOTE: these will only really be used during merging and validation.
// not sure if it would make sense to allow setting user-defined attributes/extensions
// to types insteaad of hardcoding these

NSString * const kCOContainerOrdered;
NSString * const kCOContainerAllowsDuplicates;


// Convenience types

NSDictionary *COConvenienceTypeUnorderedHoldingPaths();
NSDictionary *COConvenienceTypeUnorderedEmbeddedItem();


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
@interface COStoreItem : NSObject
{
@private
	ETUUID *uuid;
	NSMutableDictionary *types;
	NSMutableDictionary *values;
}

- (id) initWithUUID: (ETUUID*)aUUID;

- (ETUUID *)uuid;

- (NSArray *) attributeNames;

- (NSDictionary *) typeForAttribute: (NSString *)anAttribute;
- (id) valueForAttribute: (NSString*)anAttribute;

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (NSDictionary*)aType;

/** @taskunit plist import/export */

- (id)plist;
- (id)initWithPlist: (id)aPlist;
@end
