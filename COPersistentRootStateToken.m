#import "COPersistentRootStateToken.h"

#import "COUUID.h"

@implementation COPersistentRootStateToken

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
    if ([object isKindOfClass: [COPersistentRootStateToken class]])
    {
        return ((COPersistentRootStateToken *)object)->index == index
        && [((COPersistentRootStateToken *)object)->prootCache isEqual: prootCache];
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

- (id) plist
{
    return [NSString stringWithFormat: @"%@:%@", prootCache,
            [NSNumber numberWithLongLong: (long long)index]];
}
+ (COPersistentRootStateToken *) tokenWithPlist: (id)plist
{
    NSArray *comps = [(NSString *)plist componentsSeparatedByString:@":"];
    
    COPersistentRootStateToken *result = [[[COPersistentRootStateToken alloc] init] autorelease];
    
    result->prootCache = [[COUUID UUIDWithString: [comps objectAtIndex: 0]] retain];
    result->index = [(NSString *)[comps objectAtIndex: 1] longLongValue];
    
    return result;
}

@end
