#import "COStoreItem.h"

NSString * const kCOTypeKind = @"kCOTypeKind";
NSString * const kCOPrimitiveTypeKind = @"kCOPrimitiveTypeKind";
NSString * const kCOContainerTypeKind = @"kCOContainerTypeKind";

NSString * const kCOPrimitiveType = @"kCOPrimitiveType";
NSString * const kCOPrimitiveTypeInt64 = @"kCOPrimitiveTypeInt64";
NSString * const kCOPrimitiveTypeDouble = @"kCOPrimitiveTypeDouble";
NSString * const kCOPrimitiveTypeString = @"kCOPrimitiveTypeString";
NSString * const kCOPrimitiveTypeBlob = @"kCOPrimitiveTypeBlob";
NSString * const kCOPrimitiveTypeCommitUUID = @"kCOPrimitiveTypeCommitUUID";
NSString * const kCOPrimitiveTypeHoldingPath = @"kCOPrimitiveTypeHoldingPath";
NSString * const kCOPrimitiveTypeReferencePath = @"kCOPrimitiveTypeReferencePath";

NSString * const kCOContainerOrdered = @"kCOContainerOrdered";
NSString * const kCOContainerAllowsDuplicates = @"kCOContainerAllowsDuplicates";

@implementation COStoreItem

- (ETUUID *)uuid
{
	return uuid;
}

- (NSArray *) attributeNames
{
	assert([[types allKeys] isEqual: [values allKeys]]);	
	return [types allKeys];
}

- (NSDictionary *) typeForAttribute: (NSString *)anAttribute
{
	return [types objectForKey: anAttribute];
}

- (id) valueForAttribute: (NSString*)anAttribute
{
	return [values objectForKey: anAttribute];
}


- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (NSDictionary*)aType
{
	// FIXME: validate
	[types setObject: aType forKey: anAttribute];
	[values setObject: aValue forKey: anAttribute];
}


@end
