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

- (COType *) typeForAttribute: (NSString *)anAttribute
{
	return [root typeForAttribute: anAttribute];
}
- (id) valueForAttribute: (NSString*)anAttribute
{
	id rootValue = [root valueForAttribute: anAttribute];
	COType *type = [self typeForAttribute: anAttribute];
	
	if ([[type primitiveType] isEqual: [COType embeddedItemType]])
	{
		if ([type isMultivalued])
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
	 forAttribute: (NSString *)anAttribute
			 type: (COType *)aType
{
	if ([[aType primitiveType] isEqual: [COType embeddedItemType]])
	{
		if ([aType isMultivalued])
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

- (void)removeValueForAttribute: (NSString*)anAttribute
{
	[root removeValueForAttribute: anAttribute];
}

/** @taskunit I/O */

- (NSSet*) allContainedStoreItems
{
	NSMutableSet *result = [NSMutableSet set];
	
	[result addObject: root];
	
	for (NSString *key in [self attributeNames])
	{
		COType *type = [self typeForAttribute: key];
		if ([[type primitiveType] isEqual: [COType embeddedItemType]])
		{
			for (COStoreItemTree *tree in [self valueForAttribute: key])
			{
				[result unionSet: [tree allContainedStoreItems]];
			}
		}
	}
	return result;
}

/** @taskunit convenience */

- (void) addTree: (COStoreItemTree *)aValue
 forSetAttribute: (NSString*)anAttribute
{
	id container = [self valueForAttribute: anAttribute];
	
	if (container == nil)
	{
		container = [NSSet setWithObject: aValue];
	}
	else
	{
		container = [container setByAddingObject: aValue];
	}
	
	[self setValue: container
	  forAttribute: anAttribute
			  type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
}

- (void) addTree: (COStoreItemTree *)aValue
{
	[self addTree: aValue
  forSetAttribute: @"contents"];
}
- (void) removeTree: (COStoreItemTree *)aValue
{
	NSMutableSet *container = [NSMutableSet setWithSet: [self valueForAttribute: @"contents"]];
	assert([container containsObject: aValue]);
	[container removeObject: aValue];
	[self setValue: container
	  forAttribute: @"contents"
			  type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
}

- (NSSet*)contents
{
	NSSet *contents = [self valueForAttribute: @"contents"];
	if (contents != nil)
	{
		return contents;
	}
	return [NSSet set];
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

/** @taskunit equality testing */

- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
	{
		return NO;
	}
	COStoreItemTree *otherItemTree = (COStoreItemTree*)object;
	
	if (![otherItemTree->root isEqual: root]) return NO;
	
	// FIXME: we "leak" COStoreItemTrees in a way;
	// if you add some trees and then later remove them, the tree objects
	// are never cleared from the items dictionary. this is why we use
	// this more complex test for equality rather than testing the items dict.
	if (![[otherItemTree allContainedStoreItems] isEqual: [self allContainedStoreItems]]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [root hash] ^ [items hash];
}

@end

