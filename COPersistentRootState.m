#import "COPersistentRootState.h"
#import "COSubtree.h"

@implementation COPersistentRootState

- (id) initWithPlist: (NSDictionary *)aPlist
{
    self = [super init];
    tree = [[COSubtree subtreeWithPlist: aPlist] retain];
    return self;
}

- (id) plist
{
    return [tree plist];
}

- (void) dealloc
{
    [tree release];
    [super dealloc];
}

- (COSubtree *) tree
{
    return tree;
}

+ (COPersistentRootState *) stateWithTree: (COSubtree *)aTree
{
    COPersistentRootState *result = [[[COPersistentRootState alloc] init] autorelease];
    result->tree = [aTree copy];
    return result;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [COPersistentRootState class]])
    {
        return [tree isEqual: [object tree]];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [tree hash];
}

@end
