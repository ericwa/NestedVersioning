#import "COStoreItem.h"
#import "Common.h"
#import "COPath.h"
#import "COType.h"
#import "COType+Plist.h"

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

- (COType *) typeForAttribute: (NSString *)anAttribute
{
	return [types objectForKey: anAttribute];
}

- (id) valueForAttribute: (NSString*)anAttribute
{
	return [values objectForKey: anAttribute];
}

- (void) validate
{
	assert([[[types allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
			isEqual: [[values allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]]);
	
	for (NSString *attribute in [self attributeNames])
	{
		COType *type = [self typeForAttribute: attribute];
		id value = [self valueForAttribute: attribute];
		assert([type validateValue: value]);
	}
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString *)anAttribute
			 type: (COType *)aType
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
	assert([[types objectForKey: anAttribute] isMultivalued]);
	
	id container = [[values objectForKey: anAttribute] mutableCopy];
	[container addObject: aValue];
	[values setObject: container forKey: anAttribute];
	[container release];
	
	[self validate];
}

- (NSArray*) allObjectsForAttribute: (NSString*)attribute
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
		else assert(0);
	}
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
