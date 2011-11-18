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
NSString * const kCOPrimitiveTypeBlob;
NSString * const kCOPrimitiveTypeCommitUUID; // just a version uuid. prevents version from being GC'ed.
NSString * const kCOPrimitiveTypeHoldingPath; // prevents destination from being GC'ed.        copied when parent is copied
NSString * const kCOPrimitiveTypeReferencePath;// doesn't prevent destination from being GC'ed. not copied when parent is copied

// if a type is a container type, it must have these two values set to either YES or NO
// to specify the type of container.

NSString * const kCOContainerOrdered;
NSString * const kCOContainerAllowsDuplicates;

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
kCOPrimitiveTypeHoldingPath: COPath
kCOPrimitiveTypeReferencePath: COPath

for containers:
 
kCOContainerOrdered = NO, kCOContainerAllowsDuplicates = NO: NSSet
kCOContainerOrdered = NO, kCOContainerAllowsDuplicates = YES: NSCountedSet 
kCOContainerOrdered = YES, kCOContainerAllowsDuplicates = NO: NSArray
kCOContainerOrdered = YES, kCOContainerAllowsDuplicates = YES: NSArray 
 
*/


/**
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

@end
