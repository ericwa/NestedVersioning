#import "COItemTree.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COItem.h"

@implementation COItemTree

+ (COItemTree *) treeWithItems: (NSArray *)items rootUUID: (COUUID *)aUUID
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: [items count]];
    for (COItem *item in items)
    {
        [dict setObject: item forKey: [item UUID]];
    }
    
    return [[[self alloc] initWithItemForUUID: dict root: aUUID] autorelease];
}

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
                      root: (COUUID *)root
{
    NSParameterAssert([itemForUUID isKindOfClass: [NSDictionary class]]);
    NSParameterAssert([root isKindOfClass: [COUUID class]]);
    
    SUPERINIT;
    itemForUUID_ = [[NSDictionary alloc] initWithDictionary: itemForUUID copyItems: YES];
    root_ = [root copy];
    return self;
}

- (void) dealloc
{
    [itemForUUID_ release];
    [root_ release];
    [super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (COUUID *) root
{
    return root_;
}

- (COItem *) itemForUUID: (COUUID *)aUUID
{
    return [itemForUUID_ objectForKey: aUUID];
}

- (NSArray *) objectUUIDs
{
    return [itemForUUID_ allKeys];
}

- (COItemTree *) objectTreeWithNameMapping: (NSDictionary *)aMapping;
{
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	for (COUUID *uuid in itemForUUID_)
	{
        COItem *oldItem = [itemForUUID_ objectForKey: uuid];
        COItem *newItem = [[oldItem mutableCopyWithNameMapping: aMapping] autorelease];
        [newItems setObject: newItem forKey: [newItem UUID]];
	}
	
    COUUID *newRoot = [aMapping objectForKey: root_];
    if (newRoot == nil)
    {
        newRoot = root_;
    }
    
	return [[[COItemTree alloc] initWithItemForUUID: newItems root:newRoot] autorelease];
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
	
	if (![otherTree->root_ isEqual: root_]) return NO;
	if (![otherTree->itemForUUID_ isEqual: itemForUUID_]) return NO;
	return YES;
}

- (NSUInteger) hash
{
	return [root_ hash] ^ [itemForUUID_ hash] ^ 16921545442590332862ULL;
}

- (NSString *)description
{
	NSMutableString *result = [NSMutableString string];
    
	[result appendFormat: @"[COObjectTree root: %@\n", root_];
	for (COItem *item in [itemForUUID_ allValues])
	{
		[result appendFormat: @"%@", item];
	}
	[result appendFormat: @"]"];
	
	return result;
}

@end
