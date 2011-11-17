#import <Foundation/Foundation.h>
#import "ETUUID.h"

/**
 */
@interface COStoreItem : NSObject
{
@private
	ETUUID *uuid;
	NSMutableDictionary *types;
	NSMutableDictionary *values;
}

- (ETUUID *)uuid;

- (NSArray *) attributeNames;

/**

scalar types: 

in64_t, double, string, blob,
version,       // just a version uuid. prevents version from being GC'ed.
holding-path,  // prevents destination from being GC'ed.        copied when parent is copied
reference-path // doesn't prevent destination from being GC'ed. not copied when parent is copied

collecion types:
 
({scalar_type}, ordered={no/yes}, allows_duplicates={no/yes})
 

*/





// old:

/*
// scalar types

- (void) setIntegerValue: (int64_t)anInt
		forAttributeName: (NSString*)attributeName
				typeName: (NSString*)typeName;

- (void) setDoubleValue: (double)aReal
		forAttributeName: (NSString*)attributeName
				typeName: (NSString*)typeName;

- (void) setStringValue: (NSString*)aStr
	   forAttributeName: (NSString*)attributeName
			   typeName: (NSString*)typeName;

- (void) setBlobValue: (NSData*)aData
	forAttributeName: (NSString*)attributeName
			typeName: (NSString*)typeName;

// multivalued types

- (void) setArrayOfIntegers: (NSArray *)anArray
		forAttributeName: (NSString*)attributeName
				typeName: (NSString*)typeName;

- (void) setArrayOfDoubles: (NSArray *)anArray
	   forAttributeName: (NSString*)attributeName
			   typeName: (NSString*)typeName;

- (void) setArrayOfStrings: (NSArray *)anArray
		  forAttributeName: (NSString*)attributeName
				  typeName: (NSString*)typeName;

- (void) setArrayOfBlobs: (NSArray *)anArray
		 forAttributeName: (NSString*)attributeName
				 typeName: (NSString*)typeName;
*/

@end
