#import "COPersistentRootStateDelta.h"
#import "COItem.h"

NSString *kCOPersistentRootStateDeltaItems = @"COPersistentRootStateDeltaItems";
NSString *kCOPersistentRootStateDeltaRootUUID = @"COPersistentRootStateDeltaRootUUID";

@implementation COPersistentRootStateDelta

- (id) initWithNewRootItemUUID: (COUUID *)aUUID
                         items: (NSArray *)itemsArray
{
    self = [super init];
    if (self != nil)
    {
        newRootItem = [aUUID retain];
        itemForUUID = [[NSMutableDictionary alloc] init];
        for (COItem *item in itemsArray)
        {
            [(NSMutableDictionary *)itemForUUID setObject: item
                                                   forKey: [item UUID]];
        }        
    }
    return self;
}

- (void) dealloc
{
    [newRootItem release];
    [itemForUUID release];
    [super dealloc];
}

- (NSArray *) modifiedItemUUIDs
{
    return [itemForUUID allKeys];
}
- (COItem *) itemForUUID: (COUUID *)aUUID
{
    return [itemForUUID objectForKey: aUUID];
}
- (COUUID *) rootItemUUID
{
    return newRootItem;
}

- (id) plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    NSMutableArray *allItemPlists = [NSMutableArray array];
    for (COItem *item in [itemForUUID allValues])
    {
        [allItemPlists addObject: [item plist]];
    }
    
    [results setObject: allItemPlists forKey: kCOPersistentRootStateDeltaItems];
    [results setObject: [newRootItem stringValue] forKey: kCOPersistentRootStateDeltaRootUUID];

    return results;
}

- (id) initWithPlist: (id)aPlist
{
    NSMutableArray *allItems = [NSMutableArray array];
    for (id itemPlist in [aPlist objectForKey: kCOPersistentRootStateDeltaItems])
    {
        [allItems addObject: [[[COItem alloc] initWithPlist: itemPlist] autorelease]];
    }
    
    return [self initWithNewRootItemUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootStateDeltaRootUUID]]
                                   items: allItems];
}

@end
