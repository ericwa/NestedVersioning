#import "COStoreItemTree.h"
#import "Common.h"

@implementation COStoreItemTree

- (id) initWithUUID: (ETUUID*)aUUID
{
	NILARG_EXCEPTION_TEST(aUUID);
	
	SUPERINIT
	root = [[COStoreItem alloc] initWithUUID: aUUID];
	items = [[NSMutableDictionary alloc] init];
	return self;
}

- (id) init
{
	return [self initWithUUID: [ETUUID UUID]];
}

- (void) dealloc
{
	[root release];
	[items release];
	[super dealloc];
}

+ (COStoreItemTree *)itemTree
{
	return [[[self alloc] init] autorelease];
}

- (ETUUID *)UUID
{
	return [root UUID];
}

- (NSArray *) attributeNames
{
	return [root attributeNames];
}

- (NSDictionary *) typeForAttribute: (NSString *)anAttribute
{
	return [root typeForAttribute: anAttribute];
}
- (id) valueForAttribute: (NSString*)anAttribute
{
	id rootValue = [root valueForAttribute: anAttribute];
	NSDictionary *type = [self typeForAttribute: anAttribute];
	
	if ([[type objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
	{
		if ([[type objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind])
		{
			id container;
			
			if ([rootValue isKindOfClass: [NSCountedSet class]])
			{
				container = [NSCountedSet set];
			}
			else if ([rootValue isKindOfClass: [NSArray class]])
			{
				container = [NSMutableArray array];
			}
			else if ([rootValue isKindOfClass: [NSSet class]])
			{
				container = [NSMutableSet set];
			}
			else assert(0);
			
			for (ETUUID *uuid in rootValue)
			{
				assert([items objectForKey: uuid] != nil);
				[container addObject: [items objectForKey: uuid]];
			}
			
			return container;
		}
		else
		{
			assert([items objectForKey: rootValue] != nil);
			
			return [items objectForKey: rootValue];
		}
	}
	else
	{
		return rootValue;
	}
}

- (void) setValue: (id)aValue
	 forAttribute: (NSString*)anAttribute
			 type: (NSDictionary*)aType
{
	if ([[aType objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
	{
		if ([[aType objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind])
		{
			id container;
			
			if ([aValue isKindOfClass: [NSCountedSet class]])
			{
				container = [NSCountedSet set];
			}
			else if ([aValue isKindOfClass: [NSArray class]])
			{
				container = [NSMutableArray array];
			}
			else if ([aValue isKindOfClass: [NSSet class]])
			{
				container = [NSMutableSet set];
			}
			else assert(0);

			for (COStoreItemTree *aTree in aValue)
			{
				assert([aTree isKindOfClass: [COStoreItemTree class]]);
				[container addObject: [aTree UUID]];
				[items setObject: aTree forKey: [aTree UUID]];
			}
			
			[root setValue: container forAttribute: anAttribute type: aType];
		}
		else
		{
			assert([aValue isKindOfClass: [self class]]);
			[items setObject: aValue forKey: [aValue UUID]];
			[root setValue: [aValue UUID] forAttribute: anAttribute type: aType];
		}
	}
	else
	{
		[root setValue:aValue forAttribute:anAttribute type:aType];
	}
}

/** @taskunit convenience */

- (void) addObject: (id)aValue
	  forAttribute: (NSString*)anAttribute
			  type: (NSDictionary*)aType
{
	id container = [[self valueForAttribute: anAttribute] mutableCopy];
	[container addObject: aValue];
	[self setValue: container
	  forAttribute: anAttribute
			  type: aType];
	[container release];
}

- (id)copyWithZone:(NSZone *)zone
{
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	for (ETUUID *uuid in items)
	{
		COStoreItemTree *tree = [[items objectForKey: uuid] copy];
		[newItems setObject: tree forKey: uuid];
		[tree release];
	}
	
	COStoreItem *newRoot = [[root copy] autorelease];
	
	COStoreItemTree *newCopy = [[COStoreItemTree alloc] init];
	ASSIGN(newCopy->root, newRoot);
	ASSIGN(newCopy->items, newItems);
		   
	return newCopy;
}

@end

