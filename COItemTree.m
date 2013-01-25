#import "COItemTree.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COItem.h"

@implementation COItemTree

+ (COItemTree *) treeWithItems: (NSArray *)items rootItemUUID: (COUUID *)aUUID
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: [items count]];
    for (COItem *item in items)
    {
        [dict setObject: item forKey: [item UUID]];
    }
    
    return [[[self alloc] initWithItemForUUID: dict rootItemUUID: aUUID] autorelease];
}

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

- (id) copyWithZone:(NSZone *)zone
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

- (void) collectAllDescendentsOfItem: (COUUID *)aUUID inSet: (NSMutableSet *)aSet
{
	[aSet addObject: aUUID];
	for (COUUID *child in [[self itemForUUID: aUUID] embeddedItemUUIDs])
	{
        [self collectAllDescendentsOfItem: child inSet: aSet];
	}
}

- (NSArray *) itemUUIDs
{
    NSMutableSet *result = [NSMutableSet set];
    [self collectAllDescendentsOfItem: [self rootItemUUID] inSet: result];
    return [result allObjects];
}

- (COItemTree *) itemTreeWithNameMapping: (NSDictionary *)aMapping;
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
    
	return [[[COItemTree alloc] initWithItemForUUID: newItems rootItemUUID:newRoot] autorelease];
}


/** @taskunit equality testing */

- (BOOL) isEqual: (id)object
{
	if (object == self)
	{
		return YES;
	}
	if (![object isKindOfClass: [COItemTree class]])
	{
		return NO;
	}
	COItemTree *otherTree = (COItemTree*)object;
	
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
    
	[result appendFormat: @"[COObjectTree root: %@\n", rootItemUUID_];
	for (COItem *item in [itemForUUID_ allValues])
	{
		[result appendFormat: @"%@", item];
	}
	[result appendFormat: @"]"];
	
	return result;
}

@end
