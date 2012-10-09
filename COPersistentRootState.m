#import "COPersistentRootState.h"
#import "COSubtree.h"
#import "COMacros.h"
#import "COPersistentRootStateToken.h"

NSString *kCOPersistentRootStateTree = @"COPersistentRootStateTree";
NSString *kCOPersistentRootStateParentStateToken = @"COPersistentRootStateParentStateToken";


@implementation COPersistentRootState

- (id) initWithPlist: (NSDictionary *)aPlist
{
    self = [super init];
        
    id treePlist = [aPlist objectForKey: kCOPersistentRootStateTree];
    id tokenPlist = [aPlist objectForKey: kCOPersistentRootStateParentStateToken];

    assert(aPlist != nil);
    assert(treePlist != nil);
    
    ASSIGN(tree_, [COSubtree subtreeWithPlist: treePlist]);
    
    if (tokenPlist != nil)
    {
        ASSIGN(parentStateToken_, [COPersistentRootStateToken tokenWithPlist: tokenPlist]);
    }
    
    return self;
}

- (id) plist
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    [plist setObject: [tree_ plist] forKey: kCOPersistentRootStateTree];
    if (parentStateToken_ != nil)
    {
        [plist setObject: [parentStateToken_ plist] forKey: kCOPersistentRootStateParentStateToken];
    }
    return [NSDictionary dictionaryWithDictionary: plist];
}

- (void) dealloc
{
    [tree_ release];
    [parentStateToken_ release];
    [super dealloc];
}

- (COSubtree *) tree
{
    return tree_;
}

+ (COPersistentRootState *) stateWithTree: (COSubtree *)aTree
{
    COPersistentRootState *result = [[[COPersistentRootState alloc] init] autorelease];
    result->tree_ = [aTree copy];
    return result;
}

- (void) setParentStateToken: (COPersistentRootStateToken *)aToken
{
    ASSIGN(parentStateToken_, aToken);
}
- (COPersistentRootStateToken *) parentStateToken
{
    return parentStateToken_;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [COPersistentRootState class]])
    {
        return [tree_ isEqual: [object tree]]
        && ((parentStateToken_ == nil && [object parentStateToken] == nil)
            || [parentStateToken_ isEqual: [object parentStateToken]]);
    }
    return NO;
}

- (NSUInteger) hash
{
    return [tree_ hash];
}

@end
