#import "COStoreItem.h"
#import "Common.h"
#import "COPath.h"

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

// Convenience types

NSDictionary *COConvenienceTypeUnorderedHoldingPaths()
{
	return D(kCOContainerTypeKind, kCOTypeKind,
			kCOPrimitiveTypeHoldingPath, kCOPrimitiveType,
														[NSNumber numberWithBool: NO], kCOContainerOrdered,
														[NSNumber numberWithBool: NO], kCOContainerAllowsDuplicates);
}

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


/** @taskunit plist import/export */

static id exportPrimitiveToPlist(id aValue, NSDictionary *aType)
{
	NSString *primitiveType = [aType objectForKey: kCOPrimitiveType];
	
	if ([primitiveType isEqualToString: kCOPrimitiveTypeCommitUUID] ||
		[primitiveType isEqualToString: kCOPrimitiveTypeHoldingPath] ||
		[primitiveType isEqualToString: kCOPrimitiveTypeReferencePath])
	{
		return [aValue stringValue];
	}
	return aValue;
}

static id importPrimitiveFromPlist(id aValue, NSDictionary *aType)
{
	NSString *primitiveType = [aType objectForKey: kCOPrimitiveType];
	
	if ([primitiveType isEqualToString: kCOPrimitiveTypeCommitUUID])
	{
		return [ETUUID UUIDWithString: aValue];
	}
	else if ([primitiveType isEqualToString: kCOPrimitiveTypeHoldingPath] ||
			 [primitiveType isEqualToString: kCOPrimitiveTypeReferencePath])
	{
		return [COPath pathWithString: aValue];
	}
	return aValue;
}


static id exportToPlist(id aValue, NSDictionary *aType)
{
	NSString *typeKind = [aType objectForKey: kCOTypeKind];
	if ([typeKind isEqualTo: kCOPrimitiveTypeKind])
	{
		return exportPrimitiveToPlist(aValue, aType);
	}
	else if ([typeKind isEqualTo: kCOContainerTypeKind])
	{
		NSMutableArray *result = [NSMutableArray array];
		for (id obj in aValue)
		{
			[result addObject: exportPrimitiveToPlist(obj, D(kCOPrimitiveTypeKind, kCOTypeKind,
															 [aType objectForKey: kCOPrimitiveType], kCOPrimitiveType))];
		}
		return result;
	}
	assert(0);
}

static id importFromPlist(id aValue, NSDictionary *aType)
{
	NSString *typeKind = [aType objectForKey: kCOTypeKind];
	if ([typeKind isEqualTo: kCOPrimitiveTypeKind])
	{
		return importPrimitiveFromPlist(aValue, aType);
	}
	else if ([typeKind isEqualTo: kCOContainerTypeKind])
	{
		id collection;
		BOOL ordered = [[aType objectForKey: kCOContainerOrdered] boolValue];
		BOOL allowsDuplicates = [[aType objectForKey: kCOContainerAllowsDuplicates] boolValue];
		
		if (!ordered && !allowsDuplicates)
		{
			collection = [NSMutableSet set];		
		}
		else if (!ordered && allowsDuplicates)
		{
			collection = [NSCountedSet set];
		}
		else
		{
			collection = [NSMutableArray array];
		}
		
		for (id obj in aValue)
		{
			[collection addObject: importPrimitiveFromPlist(obj, D(kCOPrimitiveTypeKind, kCOTypeKind,
																   [aType objectForKey: kCOPrimitiveType], kCOPrimitiveType))];
		}
		return collection;
	}
	assert(0);
}


- (id)plist
{
	NSMutableDictionary *plistValues = [NSMutableDictionary dictionary];
	
	for (NSString *key in values)
	{
		id plistValue = exportToPlist([values objectForKey: key], [types objectForKey: key]);
		[plistValues setObject: plistValue 
						forKey: key];
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			plistValues, @"values",
			types, @"types",
			[uuid stringValue], @"uuid",
			nil];
}

- (id)initWithPlist: (id)aPlist
{
	SUPERINIT;
	ASSIGN(uuid, [ETUUID UUIDWithString: [aPlist objectForKey: @"uuid"]]);
	ASSIGN(types, [aPlist objectForKey: @"types"]);
	
	NSMutableDictionary *importedValues = [NSMutableDictionary dictionary];
	for (NSString *key in [aPlist objectForKey: @"values"])
	{
		id importedValue = importFromPlist([[aPlist objectForKey: @"values"] objectForKey: key], [types objectForKey: key]);
		[importedValues setObject: importedValue 
						   forKey: key];
	}
	
	ASSIGN(values, importedValues);
	return self;
}

/** @taskunit equality testing */

- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
	{
		return NO;
	}
	COStoreItem *otherItem = (COStoreItem*)object;
	
	if (![[otherItem uuid] isEqual: [self uuid]]) return NO;
	if (![otherItem->types isEqual: types]) return NO;
	if (![otherItem->values isEqual: values]) return NO;
	return YES;
}

@end
