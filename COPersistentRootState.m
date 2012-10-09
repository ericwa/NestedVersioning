#import "COPersistentRootState.h"
#import "COSubtree.h"
#import "COMacros.h"
#import "COPersistentRootStateToken.h"

NSString *kCOPersistentRootStateTree = @"COPersistentRootStateTree";
NSString *kCOPersistentRootStateParentStateToken = @"COPersistentRootStateParentStateToken";
NSString *kCOPersistentRootStateCommitMetadata = @"COPersistentRootStateCommitMetadata";

@implementation COPersistentRootState

- (id) initWithPlist: (NSDictionary *)aPlist
{
    self = [super init];
        
    id treePlist = [aPlist objectForKey: kCOPersistentRootStateTree];
    id tokenPlist = [aPlist objectForKey: kCOPersistentRootStateParentStateToken];
    id metadataPlist = [aPlist objectForKey: kCOPersistentRootStateCommitMetadata];
    
    assert(aPlist != nil);
    assert(treePlist != nil);
    
    ASSIGN(tree_, [COSubtree subtreeWithPlist: treePlist]);
    
    if (tokenPlist != nil)
    {
        ASSIGN(parentStateToken_, [COPersistentRootStateToken tokenWithPlist: tokenPlist]);
    }
    ASSIGN(commitMetadata_, metadataPlist);
    
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
    if (commitMetadata_ != nil)
    {
        [plist setObject: commitMetadata_ forKey: kCOPersistentRootStateCommitMetadata];
    }
    return [NSDictionary dictionaryWithDictionary: plist];
}

- (void) dealloc
{
    [tree_ release];
    [parentStateToken_ release];
    [commitMetadata_ release];
    [super dealloc];
}

- (NSDictionary *)commitMetadata
{
    return commitMetadata_;
}
- (void) setCommitMetadata: (NSDictionary*)commitMetadata
{
    ASSIGN(commitMetadata_, commitMetadata);
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
            || [parentStateToken_ isEqual: [object parentStateToken]])
        && ((commitMetadata_ == nil && [object commitMetadata] == nil)
            || [commitMetadata_ isEqual: [object commitMetadata]]);
    }
    return NO;
}

- (NSUInteger) hash
{
    return [tree_ hash];
}

@end
