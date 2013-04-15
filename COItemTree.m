#import "COItemTree.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COItem.h"

@implementation COItemTree

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root
{
    SUPERINIT;
    itemForUUID_ = [itemForUUID retain];
    rootItemUUID_ = [root copy];
    return self;
}

+ (COItemTree *)treeWithItemsRootFirst: (NSArray*)items
{
    NSParameterAssert([items count] >= 1);

    COItemTree *result = [[self alloc] init];
    result->rootItemUUID_ = [[[items objectAtIndex: 0] UUID] copy];
    result->itemForUUID_ = [[NSMutableDictionary alloc] initWithCapacity: [items count]];
    
    for (COItem *item in items)
    {
        [result->itemForUUID_ setObject: item forKey: [item UUID]];
    }
    return result;
}

- (void) dealloc
{
    [itemForUUID_ release];
    [rootItemUUID_ release];
    [super dealloc];
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

/**
 * For debugging/testing only
 */
- (BOOL) isEqualToItemTree: (COItemTree *)aTree
         comparingItemUUID: (COUUID *)aUUID
{
    COItem *my = [self itemForUUID: aUUID];
    COItem *other = [aTree itemForUUID: aUUID];
    if (![my isEqual: other])
    {
        return NO;
    }
    
    if (![[my embeddedItemUUIDs] isEqual: [other embeddedItemUUIDs]])
    {
        return NO;
    }
    
    for (COUUID *aChild in [my embeddedItemUUIDs])
    {
        if (![self isEqualToItemTree: aTree comparingItemUUID: aChild])
        {
            return NO;
        }
    }
    return YES;
}

/**
 * For debugging/testing only
 */
- (BOOL) isEqual:(id)object
{
    NSLog(@"WARNING, COItemTree should be compared for debugging only");
    
    if (![object isKindOfClass: [self class]])
    {
        return NO;
    }
    if (![[object rootItemUUID] isEqual: rootItemUUID_])
    {
        return NO;
    }
    return [self isEqualToItemTree: object comparingItemUUID: rootItemUUID_];
}

@end

