#import "COStoreItem.h"
#import "Common.h"

NSString * const kCOTypeKind = @"kCOTypeKind";
NSString * const kCOPrimitiveTypeKind = @"kCOPrimitiveTypeKind";
NSString * const kCOContainerTypeKind = @"kCOContainerTypeKind";

NSString * const kCOPrimitiveType = @"kCOPrimitiveType";
NSString * const kCOPrimitiveTypeInt64 = @"kCOPrimitiveTypeInt64";
NSString * const kCOPrimitiveTypeDouble = @"kCOPrimitiveTypeDouble";
NSString * const kCOPrimitiveTypeString = @"kCOPrimitiveTypeString";
NSString * const kCOPrimitiveTypeFullTextIndexableString = @"kCOPrimitiveTypeFullTextIndexableString";
NSString * const kCOPrimitiveTypeBlob = @"kCOPrimitiveTypeBlob";
NSString * const kCOPrimitiveTypeCommitUUID = @"kCOPrimitiveTypeCommitUUID";
NSString * const kCOPrimitiveTypeHoldingPath = @"kCOPrimitiveTypeHoldingPath";
NSString * const kCOPrimitiveTypeReferencePath = @"kCOPrimitiveTypeReferencePath";

NSString * const kCOContainerOrdered = @"kCOContainerOrdered";
NSString * const kCOContainerAllowsDuplicates = @"kCOContainerAllowsDuplicates";

@implementation COStoreItem

- (id) initWithUUID: (ETUUID*)aUUID
{
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	types = [[NSMutableDictionary alloc] init];
	values = [[NSMutableDictionary alloc] init];
	return self;
}

- (void) dealloc
{
	[types release];
	[values release];
	[super dealloc];
}

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

// <--- validation

static void validatePrimitive(id aValue, NSDictionary *aType)
{
	NSString *typeKind = [aType objectForKey: kCOTypeKind];
	if ([typeKind isEqualTo: kCOPrimitiveTypeKind])
	{
		NSString *primitiveType = [aType objectForKey: kCOPrimitiveType];
		assert(primitiveType != nil);
		
		// FIXME:
	}
	else
	{
		assert(0);
	}	
}

static void validate(id aValue, NSDictionary *aType)
{
	NSString *typeKind = [aType objectForKey: kCOTypeKind];
	if ([typeKind isEqualTo: kCOPrimitiveTypeKind])
	{
		validatePrimitive(aValue, aType);
	}
	else if ([typeKind isEqualTo: kCOContainerTypeKind])
	{
		NSNumber *ordered = [aType objectForKey: kCOContainerOrdered];
		NSNumber *allowsDuplicates = [aType objectForKey: kCOContainerAllowsDuplicates];
		assert([ordered isKindOfClass: [NSNumber class]] 
			   && [allowsDuplicates isKindOfClass: [NSNumber class]]);

		BOOL orderedVal = [ordered boolValue];
		BOOL allowsDuplicatesVal = [allowsDuplicates boolValue];
		
		if (!orderedVal && !allowsDuplicatesVal)
		{
			assert([aValue isKindOfClass: [NSSet class]]);			
		}
		else if (!orderedVal && allowsDuplicatesVal)
		{
			assert([aValue isKindOfClass: [NSCountedSet class]]);			
		}
		else if (orderedVal && !allowsDuplicatesVal)
		{
			assert([aValue isKindOfClass: [NSArray class]]);
		}
		else
		{
			assert([aValue isKindOfClass: [NSArray class]]);
		}
		
		for (id obj in aValue)
		{
			validatePrimitive(obj, D(kCOPrimitiveTypeKind, kCOTypeKind,
									 [aType objectForKey: kCOPrimitiveType], kCOPrimitiveType));
		}
	}
	else
	{
		assert(0);
	}
}

// end validation --/>

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (NSDictionary*)aType
{
	validate(aValue, aType);
	[types setObject: aType forKey: anAttribute];
	[values setObject: aValue forKey: anAttribute];
}


@end
