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
NSString * const kCOPrimitiveTypeEmbeddedItem = @"kCOPrimitiveTypeEmbeddedItem";
NSString * const kCOPrimitiveTypePath = @"kCOPrimitiveTypePath";

NSString * const kCOContainerOrdered = @"kCOContainerOrdered";
NSString * const kCOContainerAllowsDuplicates = @"kCOContainerAllowsDuplicates";

// Convenience type constructors

NSDictionary *COBagContainerType(NSString *aPrimitiveType)
{
	assert(![kCOPrimitiveTypeEmbeddedItem isEqual: aPrimitiveType]);
	
	return D(kCOContainerTypeKind, kCOTypeKind,
			 aPrimitiveType, kCOPrimitiveType,
			 [NSNumber numberWithBool: NO], kCOContainerOrdered,
			 [NSNumber numberWithBool: YES], kCOContainerAllowsDuplicates);
}
NSDictionary *COArrayContainerType(NSString *aPrimitiveType)
{
	assert(![kCOPrimitiveTypeEmbeddedItem isEqual: aPrimitiveType]);
	
	return D(kCOContainerTypeKind, kCOTypeKind,
			 aPrimitiveType, kCOPrimitiveType,
			 [NSNumber numberWithBool: YES], kCOContainerOrdered,
			 [NSNumber numberWithBool: YES], kCOContainerAllowsDuplicates);
}
NSDictionary *COSetContainerType(NSString *aPrimitiveType)
{
	return D(kCOContainerTypeKind, kCOTypeKind,
			 aPrimitiveType, kCOPrimitiveType,
			 [NSNumber numberWithBool: NO], kCOContainerOrdered,
			 [NSNumber numberWithBool: NO], kCOContainerAllowsDuplicates);
}

NSDictionary *COPrimitiveType(NSString *aPrimitiveType)
{
	return D(kCOPrimitiveTypeKind, kCOTypeKind,
			 aPrimitiveType, kCOPrimitiveType);	
}

NSString *COHumanReadableType(NSDictionary *aType)
{
	if ([[aType objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind])
	{
		BOOL ordered = [[aType objectForKey: kCOContainerOrdered] boolValue];
		BOOL allowsDuplicates = [[aType objectForKey: kCOContainerAllowsDuplicates] boolValue];
		
		NSString *prefix;
		
		if (!ordered && !allowsDuplicates)
		{
			prefix = @"Set of ";
		}
		else if (!ordered && allowsDuplicates)
		{
			prefix = @"Bag of ";
		}
		else if (ordered && !allowsDuplicates)
		{
			prefix = @"Unique Array of ";
		}
		else if (ordered && allowsDuplicates)
		{
			prefix = @"Array of ";
		}			
		
		return [prefix stringByAppendingString: 
				COHumanReadableType(COPrimitiveType([aType objectForKey: kCOPrimitiveType]))];
	}
	else if ([[aType objectForKey: kCOTypeKind] isEqual: kCOPrimitiveTypeKind])
	{
		NSString *primitiveType = [aType objectForKey: kCOPrimitiveType];
		
		if ([primitiveType isEqualToString: kCOPrimitiveTypeCommitUUID])
		{
			return @"Commit Ref";
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeEmbeddedItem])
		{
			return @"Embedded Item";
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypePath])
		{
			return @"Path";
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeInt64])
		{
			return @"Int";
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeDouble])
		{
			return @"Double";
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeBlob])
		{
			return @"Blob";
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeString])
		{
			return @"String";
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeFullTextIndexableString])
		{
			return @"Indexable String";
		}
		else
		{
			assert(0);
		}	
	}
	else assert(0);
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

- (id) init
{
	return [self initWithUUID: [ETUUID UUID]];
}

+ (COStoreItem *) item
{
	return [[[COStoreItem alloc] init] autorelease];
}

- (void) dealloc
{
	[uuid release];
	[types release];
	[values release];
	[super dealloc];
}

- (ETUUID *)UUID
{
	return uuid;
}
- (void) setUUID: (ETUUID *)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	ASSIGN(uuid, aUUID);
}

- (NSArray *) attributeNames
{
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
		
		if ([primitiveType isEqualToString: kCOPrimitiveTypeCommitUUID] ||
			[primitiveType isEqualToString: kCOPrimitiveTypeEmbeddedItem])
		{
			assert([aValue isKindOfClass: [ETUUID class]]);
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypePath])
		{
			assert([aValue isKindOfClass: [COPath class]]);
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeInt64] ||
				 [primitiveType isEqualToString: kCOPrimitiveTypeDouble])
		{
			assert([aValue isKindOfClass: [NSNumber class]]);
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeBlob])
		{
			assert([aValue isKindOfClass: [NSData class]]);
		}
		else if ([primitiveType isEqualToString: kCOPrimitiveTypeString] ||
				 [primitiveType isEqualToString: kCOPrimitiveTypeFullTextIndexableString])
		{
			assert([aValue isKindOfClass: [NSString class]]);
		}
		else
		{
			assert(0);
		}	
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

- (void) validate
{
	assert([[[types allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
			isEqual: [[values allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]]);
	
	for (NSString *attribute in [self attributeNames])
	{
		NSDictionary *type = [self typeForAttribute: attribute];
		id value = [self valueForAttribute: attribute];
		validate(value, type);
	}
}

// end validation --/>

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (NSDictionary*)aType
{
	NILARG_EXCEPTION_TEST(aValue);
	NILARG_EXCEPTION_TEST(anAttribute);
	NILARG_EXCEPTION_TEST(aType);
	
	[types setObject: aType forKey: anAttribute];
	[values setObject: aValue forKey: anAttribute];
	[self validate];
}

- (void)removeValueForAttribute: (NSString*)anAttribute
{
	[types removeObjectForKey: anAttribute];
	[values removeObjectForKey: anAttribute];
}

/** @taskunit plist import/export */

static id exportPrimitiveToPlist(id aValue, NSDictionary *aType)
{
	NSString *primitiveType = [aType objectForKey: kCOPrimitiveType];
	
	if ([primitiveType isEqualToString: kCOPrimitiveTypeCommitUUID] ||
		[primitiveType isEqualToString: kCOPrimitiveTypeEmbeddedItem] ||
		[primitiveType isEqualToString: kCOPrimitiveTypePath])
	{
		return [aValue stringValue];
	}
	return aValue;
}

static id importPrimitiveFromPlist(id aValue, NSDictionary *aType)
{
	NSString *primitiveType = [aType objectForKey: kCOPrimitiveType];
	
	if ([primitiveType isEqualToString: kCOPrimitiveTypeCommitUUID] ||
		[primitiveType isEqualToString: kCOPrimitiveTypeEmbeddedItem])
	{
		return [ETUUID UUIDWithString: aValue];
	}
	else if ([primitiveType isEqualToString: kCOPrimitiveTypePath])
	{
		return [COPath pathWithString: aValue];
	}
	return aValue;
}


static id exportToPlist(id aValue, NSDictionary *aType)
{
	NSString *typeKind = [aType objectForKey: kCOTypeKind];
	id plistValue;
	
	if ([typeKind isEqualTo: kCOPrimitiveTypeKind])
	{
		plistValue = exportPrimitiveToPlist(aValue, aType);
	}
	else if ([typeKind isEqualTo: kCOContainerTypeKind])
	{
		NSMutableArray *result = [NSMutableArray array];
		for (id obj in aValue)
		{
			[result addObject: exportPrimitiveToPlist(obj, D(kCOPrimitiveTypeKind, kCOTypeKind,
															 [aType objectForKey: kCOPrimitiveType], kCOPrimitiveType))];
		}
		plistValue = result;
	}
	else
	{
		assert(0);
	}

	assert(aType != nil);
	assert(plistValue != nil);
	
	return D(aType, @"type",
			 plistValue, @"value");
	
}

static NSDictionary *importTypeFromPlist(id aPlist)
{
	return [aPlist objectForKey: @"type"];
}

static id importValueFromPlist(id aPlist)
{
	NSDictionary *aType = importTypeFromPlist(aPlist);
	id aValue = [aPlist objectForKey: @"value"];
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
			[uuid stringValue], @"uuid",
			nil];
}

- (id)initWithPlist: (id)aPlist
{
	SUPERINIT;
	ASSIGN(uuid, [ETUUID UUIDWithString: [aPlist objectForKey: @"uuid"]]);
		
	NSMutableDictionary *importedValues = [NSMutableDictionary dictionary];
	NSMutableDictionary *importedTypes = [NSMutableDictionary dictionary];
	for (NSString *key in [aPlist objectForKey: @"values"])
	{
		id objPlist = [[aPlist objectForKey: @"values"] objectForKey: key];
		
		[importedValues setObject: importValueFromPlist(objPlist)
						   forKey: key];
		
		[importedTypes setObject: importTypeFromPlist(objPlist)
						  forKey: key];
	}
	ASSIGN(values, importedValues);
	ASSIGN(types, importedTypes);	

	[self validate];
	
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
	
	if (![[otherItem UUID] isEqual: [self UUID]]) return NO;
	if (![otherItem->types isEqual: types]) return NO;
	if (![otherItem->values isEqual: values]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [uuid hash] ^ [types hash] ^ [values hash] ^ 9014972660509684524LL;
}

/** @taskunit convenience */

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute
{
	assert([[[types objectForKey: anAttribute] objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind]);
	
	id container = [[values objectForKey: anAttribute] mutableCopy];
	[container addObject: aValue];
	[values setObject: container forKey: anAttribute];
	[container release];
	
	[self validate];
}

- (NSArray*) allObjectsForAttribute: (NSString*)attribute
{
	NSString *kind = [[self typeForAttribute: attribute] objectForKey: kCOTypeKind];
	id value = [self valueForAttribute: attribute];
	
	if ([kind isEqualToString: kCOPrimitiveTypeKind])
	{
		return [NSArray arrayWithObject: value];
	}
	else if ([kind isEqualToString: kCOContainerTypeKind])
	{
		if ([value isKindOfClass: [NSSet class]])
		{
			return [(NSSet *)value allObjects];
		}
		else if ([value isKindOfClass: [NSArray class]])
		{
			return value;
		}
		else assert(0);
	}
	else assert(0);
	
	return nil;
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
{
	[self setValue: aValue 
	  forAttribute: anAttribute
			  type: [self typeForAttribute: anAttribute]];
	
	[self validate];
}

- (id)copyWithZone:(NSZone *)zone
{
	COStoreItem *myCopy = [[[self class] alloc] initWithUUID: [self UUID]];
	[myCopy->types setDictionary: types];
	[myCopy->values setDictionary: values];
	return myCopy;
}

@end
