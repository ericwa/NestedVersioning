#import "COItem.h"
#import "Common.h"

@implementation COItem
#if 0

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

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

#endif
@end
