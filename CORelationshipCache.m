#import "CORelationshipCache.h"
#import "COUUID.h"
#import "COMacros.h"
#import "COType.h"

@implementation CORelationshipCache

#define INITIAL_DICTIONARY_CAPACITY 256
#define INITIAL_SET_CAPACITY 8

- (id) init
{
    SUPERINIT;
    referrerUUIDsForUUID_ = [[NSMutableDictionary alloc] initWithCapacity: INITIAL_DICTIONARY_CAPACITY];
    embeddedObjectParentUUIDForUUID_ = [[NSMutableDictionary alloc] initWithCapacity: INITIAL_DICTIONARY_CAPACITY];
    return self;
}

- (void) dealloc
{
    [referrerUUIDsForUUID_ release];
    [embeddedObjectParentUUIDForUUID_ release];
    [super dealloc];
}

- (COUUID *) parentForUUID: (COUUID *)anObject
{
    return [embeddedObjectParentUUIDForUUID_ objectForKey: anObject];
}

- (void) addReferrerUUID: (COUUID *)aReferrer
                 forUUID: (COUUID*)anObject
{
    NSMutableSet *set = [referrerUUIDsForUUID_ objectForKey: anObject];
    if (set == nil)
    {
        set = [[NSMutableSet alloc] initWithCapacity: INITIAL_SET_CAPACITY];
        [referrerUUIDsForUUID_ setObject: set forKey: anObject];
        [set release];
    }
    [set addObject: aReferrer];
}

- (void) removeReferrerUUID: (COUUID *)aReferrer
                    forUUID: (COUUID*)anObject
{
    [(NSMutableSet *)[referrerUUIDsForUUID_ objectForKey: anObject] removeObject: aReferrer];
}

- (NSSet *) referrersForUUID: (COUUID *)anObject
{
    return [referrerUUIDsForUUID_ objectForKey: anObject];
}


- (void) updateRelationshipCacheWithOldValue: (id)oldVal
                                     oldType: (COType *)oldType
                                    newValue: (id)newVal
                                     newType: (COType *)newType
                                 forProperty: (NSString *)aProperty
                                    ofObject: (COUUID *)anObject
{
    // Remove possibly stale cache entries
    
    if ([[oldType primitiveType] isEqual: [COType embeddedItemType]])
    {
        if ([oldType isMultivalued])
        {
            for (id obj in oldVal)
            {
                [embeddedObjectParentUUIDForUUID_ removeObjectForKey: obj];
            }
        }
        else
        {
            [embeddedObjectParentUUIDForUUID_ removeObjectForKey: oldVal];
        }
    }
    else if ([[oldType primitiveType] isEqual: [COType referenceType]])
    {
        if ([oldType isMultivalued])
        {
            for (id obj in oldVal)
            {
                [self removeReferrerUUID: anObject forUUID: obj];
            }
        }
        else
        {
            [self removeReferrerUUID: anObject forUUID: oldVal];
        }
    }
    
    // Maybe add new cache entries
    
    if ([[newType primitiveType] isEqual: [COType embeddedItemType]])
    {
        if ([newType isMultivalued])
        {
            for (id obj in newVal)
            {
                [embeddedObjectParentUUIDForUUID_ setObject: anObject forKey: obj];
            }
        }
        else
        {
            [embeddedObjectParentUUIDForUUID_ setObject: anObject forKey: newVal];
        }
    }
    else if ([[newType primitiveType] isEqual: [COType referenceType]])
    {
        if ([newType isMultivalued])
        {
            for (id obj in newVal)
            {
                [self addReferrerUUID: anObject forUUID: obj];
            }
        }
        else
        {
            [self addReferrerUUID: anObject forUUID: oldVal];
        }
    }
}

- (void) updateRelationshipCacheWithOldItems: (NSArray *)oldItems
                                    newItems: (NSArray *)newItems
{
    for (COItem *oldItem in oldItems)
    {
        
    }
    
    for (COItem *newItem in newItems)
    {
        
    }
}

@end
