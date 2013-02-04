#import "COItemTree.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COItem.h"

@implementation COPartialItemTree

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root
{
    NSParameterAssert([itemForUUID isKindOfClass: [NSDictionary class]]);
    NSParameterAssert([root isKindOfClass: [COUUID class]]);
    
    SUPERINIT;
    itemForUUID_ = [[NSDictionary alloc] initWithDictionary: itemForUUID copyItems: YES];
    rootItemUUID_ = [root copy];
    return self;
}

- (void) dealloc
{
    [itemForUUID_ release];
    [rootItemUUID_ release];
    [super dealloc];
}

+ (id) itemTreeWithItems: (NSArray *)items rootItemUUID: (COUUID *)aUUID
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: [items count]];
    for (COItem *item in items)
    {
        [dict setObject: item forKey: [item UUID]];
    }
    
    return [[[self alloc] initWithItemForUUID: dict rootItemUUID: aUUID] autorelease];
}

- (id) copyWithZone: (NSZone *)zone
{
    return [self retain];
}

- (COUUID *) rootItemUUID
{
    return rootItemUUID_;
}

- (COItem *) itemForUUID: (COUUID *)aUUID
{
    return [itemForUUID_ objectForKey: aUUID];
}

- (NSArray *) itemUUIDs
{
    return [itemForUUID_ allKeys];
}

- (id) itemTreeByAddingItemTree: (COPartialItemTree *)partialTree
{
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithDictionary: itemForUUID_];
    [resultDict addEntriesFromDictionary: partialTree->itemForUUID_];
    return [[[[self class] alloc] initWithItemForUUID: resultDict
                                         rootItemUUID: partialTree->rootItemUUID_] autorelease];
}

- (id) itemTreeWithNameMapping: (NSDictionary *)aMapping;
{
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	for (COUUID *uuid in itemForUUID_)
	{
        COItem *oldItem = [itemForUUID_ objectForKey: uuid];
        COItem *newItem = [[oldItem mutableCopyWithNameMapping: aMapping] autorelease];
        [newItems setObject: newItem forKey: [newItem UUID]];
	}
	
    COUUID *newRoot = [aMapping objectForKey: rootItemUUID_];
    if (newRoot == nil)
    {
        newRoot = rootItemUUID_;
    }
    
	return [[[[self class] alloc] initWithItemForUUID: newItems rootItemUUID:newRoot] autorelease];
}

- (COItemTree *) itemTree
{
	return [[[COItemTree alloc] initWithItemForUUID: itemForUUID_
                                       rootItemUUID: rootItemUUID_] autorelease];

}

/** @taskunit equality testing */

- (BOOL) isEqual: (id)object
{
	if (object == self)
	{
		return YES;
	}
	if (![object isKindOfClass: [COPartialItemTree class]])
	{
		return NO;
	}
	COPartialItemTree *otherTree = (COPartialItemTree*)object;
	
	if (![otherTree->rootItemUUID_ isEqual: rootItemUUID_]) return NO;
	if (![otherTree->itemForUUID_ isEqual: itemForUUID_]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [rootItemUUID_ hash] ^ [itemForUUID_ hash] ^ 16921545442590332862ULL;
}

- (NSString *)description
{
	NSMutableString *result = [NSMutableString string];
    
	[result appendFormat: @"[%@ root: %@\n", NSStringFromClass([self class]), rootItemUUID_];
	for (COItem *item in [itemForUUID_ allValues])
	{
		[result appendFormat: @"%@", item];
	}
	[result appendFormat: @"]"];
	
	return result;
}

@end

@implementation COItemTree

+ (void) collectAllDescendentsOfItem: (COUUID *)aUUID
                               inSet: (NSMutableSet *)dest
                  withItemDictionary: (NSDictionary *)aDict
{
    if ([dest containsObject: aUUID])
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"Cycle detected"];
    }
	[dest addObject: aUUID];
	for (COUUID *child in [[aDict objectForKey: aUUID] embeddedItemUUIDs])
	{
        [self collectAllDescendentsOfItem: child
                                    inSet: dest
                       withItemDictionary: aDict];
	}
}

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root
{
    NSMutableSet *itemsToKeep = [NSMutableSet setWithCapacity: [itemForUUID count]];
    [COItemTree collectAllDescendentsOfItem: root
                                      inSet: itemsToKeep
                         withItemDictionary: itemForUUID];
    
    NSMutableDictionary *filteredDictionary = [NSMutableDictionary dictionaryWithCapacity:[itemsToKeep count]];
    for (COUUID *uuid in itemsToKeep)
    {
        [filteredDictionary setObject: [itemForUUID objectForKey: uuid] forKey: uuid];
    }
    
    return [super initWithItemForUUID: filteredDictionary
                         rootItemUUID: root];
}

@end
