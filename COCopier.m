#import "COCopier.h"
#import "COUUID.h"

@implementation COCopier

- (void) collectItemAndAllDescendents: (COUUID *)aUUID
                                inSet: (NSMutableSet *)dest
                            fromGraph: (id<COItemGraph>)source
{
    [dest addObject: aUUID];
    for (COUUID *child in [[source itemForUUID: aUUID] embeddedItemUUIDs])
    {
        if (![dest containsObject: child])
        {
            [self collectItemAndAllDescendents: child
                                         inSet: dest
                                     fromGraph: source];
        }
        else
        {
            [NSException raise: NSInvalidArgumentException
                        format: @"Cycle detected"];
        }
    }
}

- (NSSet*) itemAndAllDescendents: (COUUID *)aUUID
                       fromGraph: (id<COItemGraph>)source
{
    NSMutableSet *result = [NSMutableSet set];
    [self collectItemAndAllDescendents: aUUID inSet: result fromGraph: source];
    return result;
}



- (NSSet *) itemUUIDsToCopyForItemItemWithUUID: (COUUID*)aUUID
                                     fromGraph: (id<COItemGraph>)source
                                       toGraph: (id<COItemGraph>)dest
{
    NSSet *itemAndAllDescendents = [self itemAndAllDescendents: aUUID fromGraph: source];
    
    if (source == dest)
    {
        // Copy all composite objects
        return itemAndAllDescendents;
    }
    else
    {
        // Copy all composite objects as well as all referenced objects
        NSMutableSet *itemAndAllReferenced = [NSMutableSet set];
        for (COUUID *uuid in itemAndAllDescendents)
        {
            [itemAndAllReferenced addObject: uuid];
            [itemAndAllReferenced unionSet: [[source itemForUUID: uuid] referencedItemUUIDs]];
        }
        return itemAndAllReferenced;
    }
}


- (COUUID*) copyItemWithUUID: (COUUID*)aUUID
                   fromGraph: (id<COItemGraph>)source
                     toGraph: (id<COItemGraph>)dest
{
    NSSet *uuidsToCopy = [self itemUUIDsToCopyForItemItemWithUUID: aUUID
                                                        fromGraph: source
                                                          toGraph: dest];
    
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    for (COUUID *oldUUID in uuidsToCopy)
    {
        [mapping setObject: [COUUID UUID]
                    forKey: oldUUID];
    }
    
    for (COUUID *uuid in uuidsToCopy)
    {
        COItem *oldItem = [source itemForUUID: uuid];
        COItem *newItem = [[oldItem mutableCopyWithNameMapping: mapping] autorelease];
        [dest addItem: newItem];
    }
    
    return [mapping objectForKey: aUUID];
}

@end
