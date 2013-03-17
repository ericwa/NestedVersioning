#import "COItem.h"
#import "COMacros.h"
#import "COPath.h"
#import "COType.h"
#import "COType+Plist.h"

static NSDictionary *copyValueDictionary(NSDictionary *input, BOOL mutable)
{
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in input)
	{
		id obj = [input objectForKey: key];
		
		if ([obj isKindOfClass: [NSCountedSet class]])
		{
			// FIXME: Always mutable
			[result setObject: obj
					   forKey: key];
		}
		else if ([obj isKindOfClass: [NSSet class]])
		{
			[result setObject: [(mutable ? [NSMutableSet class] : [NSSet class]) setWithSet: obj]
					   forKey: key];
		}
		else if ([obj isKindOfClass: [NSArray class]])
		{
			[result setObject: [(mutable ? [NSMutableArray class] : [NSArray class]) arrayWithArray: obj]
					   forKey: key];
		}
		else
		{
			[result setObject: obj forKey: key];
		}
	}
	
	if (!mutable)
	{
		NSDictionary *immutable = [[NSDictionary alloc] initWithDictionary: result];
		[result release];
		return immutable;
	}
	return result;
}

@implementation COItem

- (id) initWithUUID: (COUUID *)aUUID
 typesForAttributes: (NSDictionary *)typesForAttributes
valuesForAttributes: (NSDictionary *)valuesForAttributes
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(typesForAttributes);
	NILARG_EXCEPTION_TEST(valuesForAttributes);
		
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	types = [[NSDictionary alloc] initWithDictionary: typesForAttributes];
	values = copyValueDictionary(valuesForAttributes, NO);

	return self;
}

- (void) dealloc
{
	[uuid release];
	[types release];
	[values release];
	[super dealloc];
}

+ (COItem *) itemWithTypesForAttributes: (NSDictionary *)typesForAttributes
						 valuesForAttributes: (NSDictionary *)valuesForAttributes
{
	return [[[self alloc] initWithUUID: [COUUID UUID]
					typesForAttributes: typesForAttributes
				   valuesForAttributes: valuesForAttributes] autorelease];
}

- (COUUID *)UUID
{
	return uuid;
}

- (NSSet *) attributeNames
{
	return [NSSet setWithArray: [types allKeys]];
}

- (COType *) typeForAttribute: (NSString *)anAttribute
{
	return [types objectForKey: anAttribute];
}

- (id) valueForAttribute: (NSString *)anAttribute
{
	return [values objectForKey: anAttribute];
}

/** @taskunit plist import/export */

static id exportToPlist(id aValue, COType *aType)
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity: 2];
	[result setObject: [aType stringValue] forKey: @"type"];
	[result setObject: [aType plistValueForValue: aValue] forKey: @"value"];
	return result;
}

static COType *importTypeFromPlist(id aPlist)
{
	return [COType typeWithString: [aPlist objectForKey: @"type"]];
}

static id importValueFromPlist(id aPlist)
{
	return [importTypeFromPlist(aPlist) valueForPlistValue: [aPlist objectForKey: @"value"]];
}

- (id) plist
{
	NSMutableDictionary *plistValues = [NSMutableDictionary dictionaryWithCapacity: [values count]];
	
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

- (id) initWithPlist: (id)aPlist
{
	COUUID *aUUID = [COUUID UUIDWithString: [aPlist objectForKey: @"uuid"]];
		
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
	
	return [self initWithUUID: aUUID
		   typesForAttributes: importedTypes
		  valuesForAttributes: importedValues];
}

/** @taskunit equality testing */

- (BOOL) isEqual: (id)object
{
	if (object == self)
	{
		return YES;
	}
	if (![object isKindOfClass: [COItem class]])
	{
		return NO;
	}
	COItem *otherItem = (COItem*)object;
	
	if (![otherItem->uuid isEqual: uuid]) return NO;
	if (![otherItem->types isEqual: types]) return NO;
	if (![otherItem->values isEqual: values]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [uuid hash] ^ [types hash] ^ [values hash] ^ 9014972660509684524LL;
}

/** @taskunit convenience */

- (NSArray *) allObjectsForAttribute: (NSString *)attribute
{
	id value = [self valueForAttribute: attribute];
	
	if ([[self typeForAttribute: attribute] isPrimitive])
	{
		return [NSArray arrayWithObject: value];
	}
	else
	{
		if ([value isKindOfClass: [NSSet class]])
		{
			return [(NSSet *)value allObjects];
		}
		else if ([value isKindOfClass: [NSArray class]])
		{
			return value;
		}
		else
		{
			return [NSArray array];
		}
	}
}

- (NSSet *) embeddedItemUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (NSString *key in [self attributeNames])
	{
		COType *type = [self typeForAttribute: key];
		if ([type isPrimitiveTypeEqual: [COType embeddedItemType]])
		{		
			for (COUUID *embedded in [self allObjectsForAttribute: key])
			{
				[result addObject: embedded];
			}
		}
	}
	return [NSSet setWithSet: result];
}

- (NSSet *) referencedItemUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (NSString *key in [self attributeNames])
	{
		COType *type = [self typeForAttribute: key];
		if ([type isPrimitiveTypeEqual: [COType referenceType]])
		{
			for (COUUID *embedded in [self allObjectsForAttribute: key])
			{
				[result addObject: embedded];
			}
		}
	}
	return [NSSet setWithSet: result];
}


// Helper methods for doing GC

- (NSSet *) attachments
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (NSString *key in [self attributeNames])
	{
		COType *type = [self typeForAttribute: key];
		if ([type isPrimitiveTypeEqual: [COType attachmentType]])
		{
			for (NSData *embedded in [self allObjectsForAttribute: key])
			{
				[result addObject: embedded];
			}
		}
	}
	return [NSSet setWithSet: result];
}

- (NSSet *) allReferencedPersistentRootUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	
	for (NSString *key in [self attributeNames])
	{
		COType *type = [self typeForAttribute: key];
		if ([type isPrimitiveTypeEqual: [COType pathType]])
		{
			for (COPath *path in [self allObjectsForAttribute: key])
			{
				[result addObject: [path persistentRoot]];
			}
		}
	}
	return [NSSet setWithSet: result];
}

- (NSString *) fullTextSearchContent
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *key in [self attributeNames])
	{
		COType *type = [self typeForAttribute: key];
		if ([type isPrimitiveTypeEqual: [COType stringType]])
		{
			[result addObject: [self valueForAttribute: key]];
		}
	}
    return [result componentsJoinedByString: @" "];
}

- (NSString *)description
{
	NSMutableString *result = [NSMutableString string];
		
	[result appendFormat: @"{ COItem %@\n", uuid];
	
	for (NSString *attrib in [self attributeNames])
	{
		[result appendFormat: @"\t%@ <%@> = '%@'\n",
			attrib,
			[self typeForAttribute: attrib],
			[self valueForAttribute:attrib]];
	}
	
	[result appendFormat: @"}"];
	
	return result;
}

/** @taskunit copy */

- (id) copyWithZone: (NSZone *)zone
{
	return [self retain];
}

- (id) mutableCopyWithZone: (NSZone *)zone
{
	return [[COMutableItem alloc] initWithUUID: uuid			
								 typesForAttributes: types
								valuesForAttributes: values];
}

- (id)mutableCopyWithNameMapping: (NSDictionary *)aMapping
{
	COMutableItem *aCopy = [self mutableCopy];
	
	COUUID *newUUIDForSelf = [aMapping objectForKey: [self UUID]];
	if (newUUIDForSelf != nil)
	{
		[aCopy setUUID: newUUIDForSelf];
	}
	
	for (NSString *attr in [aCopy attributeNames])
	{
		id value = [aCopy valueForAttribute: attr];
		COType *type = [aCopy typeForAttribute: attr];
		
		if ([type isPrimitiveTypeEqual: [COType embeddedItemType]])
		{
			if ([type isPrimitive])
			{
				COUUID *UUIDValue = (COUUID*)value;
				if ([aMapping objectForKey: UUIDValue] != nil)
				{
					[aCopy setValue: [aMapping objectForKey: UUIDValue]
						 forAttribute: attr
								 type: type];
				}
			}
			else
			{ 
				id newCollection = [[value mutableCopy] autorelease];
				[newCollection removeAllObjects];
				
				for (COUUID *UUIDValue in value)
				{
					COUUID *newUUIDValue = UUIDValue;
					if ([aMapping objectForKey: UUIDValue] != nil)
					{
						newUUIDValue = [aMapping objectForKey: UUIDValue];
					}
					[newCollection addObject: newUUIDValue];
				}
				
				[aCopy setValue: newCollection
				   forAttribute: attr
						   type: type];
			}
		}
		else if ([type isPrimitiveTypeEqual: [COType pathType]])
		{
			if ([type isPrimitive])
			{
				COPath *pathValue = (COPath*)value;
				
				[aCopy setValue: [pathValue pathWithNameMapping: aMapping]
				   forAttribute: attr
						   type: type];
			}
			else
			{ 
				id newCollection = [[value mutableCopy] autorelease];
				[newCollection removeAllObjects];
				
				for (COPath *pathValue in value)
				{
					[newCollection addObject: [pathValue pathWithNameMapping:aMapping]];
				}
				
				[aCopy setValue: newCollection
				   forAttribute: attr
						   type: type];
			}
		}
	}
	
	return aCopy;
}

@end




@implementation COMutableItem

+ (COMutableItem *) itemWithTypesForAttributes: (NSDictionary *)typesForAttributes
						   valuesForAttributes: (NSDictionary *)valuesForAttributes
{
    return (COMutableItem *)[super itemWithTypesForAttributes: typesForAttributes
                                          valuesForAttributes: valuesForAttributes];
}

- (id) initWithUUID: (COUUID *)aUUID
 typesForAttributes: (NSDictionary *)typesForAttributes
valuesForAttributes: (NSDictionary *)valuesForAttributes
{
	NILARG_EXCEPTION_TEST(aUUID);
	NILARG_EXCEPTION_TEST(typesForAttributes);
	NILARG_EXCEPTION_TEST(valuesForAttributes);
	
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	types = [[NSMutableDictionary alloc] initWithDictionary: typesForAttributes];
	values = copyValueDictionary(valuesForAttributes, YES);
	
	return self;
}

- (id) initWithUUID: (COUUID*)aUUID
{
	return [self initWithUUID: aUUID
		   typesForAttributes: [NSDictionary dictionary]
		  valuesForAttributes: [NSDictionary dictionary]];
}

- (id) init
{
	return [self initWithUUID: [COUUID UUID]];
}

+ (COMutableItem *) item
{
	return [[[self alloc] init] autorelease];
}

- (void) setUUID: (COUUID *)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	ASSIGN(uuid, aUUID);
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString *)anAttribute
			 type: (COType *)aType
{
	NILARG_EXCEPTION_TEST(aValue);
	NILARG_EXCEPTION_TEST(anAttribute);
	NILARG_EXCEPTION_TEST(aType);
	
	[(NSMutableDictionary *)types setObject: aType forKey: anAttribute];
	[(NSMutableDictionary *)values setObject: aValue forKey: anAttribute];
}

- (void)removeValueForAttribute: (NSString*)anAttribute
{
	[(NSMutableDictionary *)types removeObjectForKey: anAttribute];
	[(NSMutableDictionary *)values removeObjectForKey: anAttribute];
}

/** @taskunit convenience */

- (void)   addObject: (id)aValue
toUnorderedAttribute: (NSString*)anAttribute
				type: (COType *)aType
{
	if (![aType isMultivalued] || [aType isOrdered])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected unordered type"];
	}
	
	if ([self typeForAttribute: anAttribute] == nil)
	{
		[self setValue: [NSSet set]
		  forAttribute: anAttribute
				  type: aType];
	}
		 
	NSMutableSet *set = [[self valueForAttribute: anAttribute] mutableCopy];
	NSAssert([set isKindOfClass: [NSMutableSet class]], @"expected NSMutableSet");
	[set addObject: aValue];
	[self setValue: set
	  forAttribute: anAttribute
			  type: aType];
	[set release];
}

- (void)   addObject: (id)aValue
  toOrderedAttribute: (NSString*)anAttribute
			 atIndex: (NSUInteger)anIndex
				type: (COType *)aType
{
	if (![aType isMultivalued] || ![aType isOrdered])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected ordered type"];
	}
	
	if ([self typeForAttribute: anAttribute] == nil)
	{
		[self setValue: [NSMutableArray array]
		  forAttribute: anAttribute
				  type: aType];
	}
	
	NSMutableArray *array = [[self valueForAttribute: anAttribute] mutableCopy];
	NSAssert([array isKindOfClass: [NSMutableArray class]], @"expected NSMutableArray");
	[array insertObject: aValue
				atIndex: anIndex];
	[self setValue: array
	  forAttribute: anAttribute
			  type: aType];
	[array release];
}

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute
{
	assert([[types objectForKey: anAttribute] isMultivalued]);
	
    id container = [values objectForKey: anAttribute];
    if (![container isKindOfClass: [NSMutableArray class]]
        && ![container isKindOfClass: [NSMutableSet class]])
    {
        container = [[container mutableCopy] autorelease];
        [(NSMutableDictionary *)values setObject: container forKey: anAttribute];
        
    }
    [container addObject: aValue];
}


- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
{
	[self setValue: aValue 
	  forAttribute: anAttribute
			  type: [self typeForAttribute: anAttribute]];
}

- (id) copyWithZone: (NSZone *)zone
{
	return [[COItem alloc] initWithUUID: uuid
                     typesForAttributes: types
                    valuesForAttributes: values];
}

@end

