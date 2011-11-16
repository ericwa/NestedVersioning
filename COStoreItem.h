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

@end
