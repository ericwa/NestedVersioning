#import "CORevisionID.h"

#import "COUUID.h"

@implementation CORevisionID

- (id) initWithProotCache: (COUUID *)aUUID
                    index: (int64_t)anIndex
{
    self = [super init];
    if (self != nil)
    {
        prootCache = [aUUID retain];
        index = anIndex;
    }
    return self;
}

- (void) dealloc
{
    [prootCache release];
    [super dealloc];
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [CORevisionID class]])
    {
        return ((CORevisionID *)object)->index == index
        && [((CORevisionID *)object)->prootCache isEqual: prootCache];
    }
    return NO;
}

- (NSUInteger) hash
{
    return index ^ [prootCache hash];
}
- (COUUID *) _prootCache
{
    return prootCache;
}
- (int64_t) _index
{
    return index;
}

- (CORevisionID *) revisionIDWithIndex: (int64_t)anIndex
{
    return [[[CORevisionID alloc] initWithProotCache: prootCache
                                               index: anIndex] autorelease];
}

- (id) plist
{
    return [NSString stringWithFormat: @"%@:%@", prootCache,
            [NSNumber numberWithLongLong: (long long)index]];
}
+ (CORevisionID *) tokenWithPlist: (id)plist
{
    NSArray *comps = [(NSString *)plist componentsSeparatedByString:@":"];
    
    CORevisionID *result = [[[CORevisionID alloc] init] autorelease];
    
    result->prootCache = [[COUUID UUIDWithString: [comps objectAtIndex: 0]] retain];
    result->index = [(NSString *)[comps objectAtIndex: 1] longLongValue];
    
    return result;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"<State Token %@.%lld>", prootCache, (long long int)index];
}

@end
