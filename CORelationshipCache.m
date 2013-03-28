#import "CORelationshipCache.h"
#import "COUUID.h"
#import "COMacros.h"
#import "COType.h"

@implementation CORelationshipRecord

@synthesize uuid = uuid_;
@synthesize property = property_;

+ (CORelationshipRecord *) recordWithUUID: (COUUID *)aUUID property: (NSString *)aProp
{
    CORelationshipRecord *result = [[[self alloc] init] autorelease];
    result.uuid = aUUID;
    result.property = aProp;
    return result;
}

- (void) dealloc
{
    [uuid_ release];
    [property_ release];
    [super dealloc];
}

- (NSUInteger)hash
{
    return *(NSUInteger *)(uuid_->uuid);
}

- (BOOL)isEqual:(id)object
{
	CORelationshipRecord *other = object;
    return [property_ isEqualToString: other->property_]
        && (0 == memcmp(uuid_->uuid, other->uuid_->uuid, 16));
}

@end

@implementation CORelationshipCache

#define INITIAL_DICTIONARY_CAPACITY 256
#define INITIAL_SET_CAPACITY 8

- (id) init
{
    SUPERINIT;
    referrerUUIDsForUUID_ = [[NSMutableDictionary alloc] initWithCapacity: INITIAL_DICTIONARY_CAPACITY];
    embeddedObjectParentUUIDForUUID_ = [[NSMutableDictionary alloc] initWithCapacity: INITIAL_DICTIONARY_CAPACITY];
    tempRecord_ = [[CORelationshipRecord alloc] init];
    return self;
}

- (void) dealloc
{
    [referrerUUIDsForUUID_ release];
    [embeddedObjectParentUUIDForUUID_ release];
    [tempRecord_ release];
    [super dealloc];
}

- (CORelationshipRecord *) parentForUUID: (COUUID *)anObject
{
    return [embeddedObjectParentUUIDForUUID_ objectForKey: anObject];
}

- (void) setParentUUID: (COUUID *)aParent
               forUUID: (COUUID*)anObject
           forProperty: (NSString *)aProperty
{
    CORelationshipRecord *record = [[CORelationshipRecord alloc] init];
    record.uuid = aParent;
    record.property = aProperty;
    [embeddedObjectParentUUIDForUUID_ setObject: record forKey: anObject];
    [record release];
}

- (void) clearParentForUUID: (COUUID*)anObject
{
    [embeddedObjectParentUUIDForUUID_ removeObjectForKey: anObject];
}

- (void) addReferrerUUID: (COUUID *)aReferrer
                 forUUID: (COUUID*)anObject
             forProperty: (NSString *)aProperty
{
    NSMutableSet *set = [referrerUUIDsForUUID_ objectForKey: anObject];
    if (set == nil)
    {
        set = [[NSMutableSet alloc] initWithCapacity: INITIAL_SET_CAPACITY];
        [referrerUUIDsForUUID_ setObject: set forKey: anObject];
        [set release];
    }
    
    CORelationshipRecord *record = [[CORelationshipRecord alloc] init];
    record.uuid = aReferrer;
    record.property = aProperty;
    [set addObject: record];
    [record release];
}

- (void) removeReferrerUUID: (COUUID *)aReferrer
                    forUUID: (COUUID*)anObject
                forProperty: (NSString *)aProperty
{
    tempRecord_.uuid = aReferrer;
    tempRecord_.property = aProperty;
    [(NSMutableSet *)[referrerUUIDsForUUID_ objectForKey: anObject] removeObject: tempRecord_];
}

- (NSSet *) referrersForUUID: (COUUID *)anObject
{
    return [referrerUUIDsForUUID_ objectForKey: anObject];
}

- (NSSet *) referrersForUUID: (COUUID *)anObject
            propertyInParent: (NSString*)propInParent
{
    NSMutableSet *results = [NSMutableSet set];
    NSSet *all = [referrerUUIDsForUUID_ objectForKey: anObject];
    
    for (CORelationshipRecord *record in all)
    {
        if ([record.property isEqualToString: propInParent])
        {
            [results addObject: record.uuid];
        }
    }
    return results;
}

- (void) updateRelationshipCacheWithOldValue: (id)oldVal
                                     oldType: (COType *)oldType
                                    newValue: (id)newVal
                                     newType: (COType *)newType
                                 forProperty: (NSString *)aProperty
                                    ofObject: (COUUID *)anObject
{
    // Remove possibly stale cache entries
    
    if (oldVal != nil)
    {
        if ([[oldType primitiveType] isEqual: [COType embeddedItemType]])
        {
            if ([oldType isMultivalued])
            {
                for (id obj in oldVal)
                {
                    [self clearParentForUUID: obj];
                }
            }
            else
            {
                [self clearParentForUUID: oldVal];
            }
        }
        else if ([[oldType primitiveType] isEqual: [COType referenceType]])
        {
            if ([oldType isMultivalued])
            {
                for (id obj in oldVal)
                {
                    [self removeReferrerUUID: anObject forUUID: obj forProperty: aProperty];
                }
            }
            else
            {
                [self removeReferrerUUID: anObject forUUID: oldVal forProperty: aProperty];
            }
        }
    }
    
    // Maybe add new cache entries
    
    if (newVal != nil)
    {
        if ([[newType primitiveType] isEqual: [COType embeddedItemType]])
        {
            if ([newType isMultivalued])
            {
                for (id obj in newVal)
                {
                    [self setParentUUID: anObject forUUID: obj forProperty: aProperty];
                }
            }
            else
            {
                [self setParentUUID: anObject forUUID: newVal forProperty: aProperty];
            }
        }
        else if ([[newType primitiveType] isEqual: [COType referenceType]])
        {
            if ([newType isMultivalued])
            {
                for (id obj in newVal)
                {
                    [self addReferrerUUID: anObject forUUID: obj forProperty: aProperty];
                }
            }
            else
            {
                [self addReferrerUUID: anObject forUUID: newVal forProperty: aProperty];
            }
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

- (void) removeAllEntries
{
    [embeddedObjectParentUUIDForUUID_ removeAllObjects];
    [referrerUUIDsForUUID_ removeAllObjects];
}

@end
