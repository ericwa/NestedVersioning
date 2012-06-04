#import <Foundation/Foundation.h>
#import "COBranch.h"
#import "COPersistentRootStateToken.h"
#import "COMacros.h"

NSString *kCOBranchUUID = @"COBranchUUID";
NSString *kCOBranchName = @"COBranchName";
NSString *kCOBranchStateTokens = @"COBranchStateTokens";
NSString *kCOBranchCurrentStateToken = @"COBranchCurrentStateToken";
NSString *kCOBranchMetadata = @"COBranchMetadata";

@implementation COBranch

- (id) initWithUUID: (COUUID *)aUUID
               name: (NSString *)name
       initialState: (COPersistentRootStateToken *)state
           metadata: (id)aMetadata
{
    self = [super init];
    uuid_ = [aUUID copy];
    name_ = [name copy];
    stateTokens = [[NSMutableArray alloc] init];
    [stateTokens addObject: state];
    currentState = [state retain];
    metadata = [aMetadata copy];
    
    return self;
}

- (void) dealloc
{
    [uuid_ release];
    [name_ release];
    [stateTokens release];
    [currentState release];
    [metadata release];
    [super dealloc];
}

- (COUUID *)UUID
{
    return uuid_;
}
- (void) setUUID: (COUUID *)aUUID
{
    ASSIGN(uuid_, aUUID);
}

- (NSString *)name
{
    return name_;
}
- (COPersistentRootStateToken *)currentState
{
    return currentState;
}
- (NSArray *)allCommits
{
    return stateTokens;
}

- (id) metadata
{
    return metadata;
}

- (NSArray *) _stateTokensPlist
{
    NSMutableArray *result = [NSMutableArray array];
    for (COPersistentRootStateToken *token in stateTokens)
    {
        [result addObject: [token plist]];
    }
    return result;
}

+ (NSArray *) _stateTokensArrayFromPlist: (NSArray *)array
{
    NSMutableArray *result = [NSMutableArray array];
    for (id plist in array)
    {
        [result addObject: [COPersistentRootStateToken tokenWithPlist: plist]];
    }
    return result;
}

- (id) _plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    [results setObject: [uuid_ stringValue] forKey: kCOBranchUUID];
    [results setObject: name_ forKey: kCOBranchName];
    
    [results setObject: [self _stateTokensPlist] forKey: kCOBranchStateTokens];
    
    [results setObject: [currentState plist] forKey: kCOBranchCurrentStateToken];
    
    if (metadata != nil)
    {
        [results setObject: metadata forKey: kCOBranchMetadata];
    }
    return results;
}
+ (COBranch *) _branchWithPlist: (id)plist
{
    COBranch *result = [[[COBranch alloc] init] autorelease];
    result->uuid_ = [[COUUID alloc] initWithString: [plist objectForKey: kCOBranchUUID]];
    result->name_ = [[plist objectForKey: kCOBranchName] retain];
    result->stateTokens = [[self _stateTokensArrayFromPlist: [plist objectForKey: kCOBranchStateTokens]] mutableCopy];
    result->currentState = [[COPersistentRootStateToken tokenWithPlist: [plist objectForKey: kCOBranchCurrentStateToken]] retain];
    result->metadata = [[plist objectForKey: kCOBranchMetadata] retain];
    return result;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [self class]])
    {
        COBranch *otherBranch = (COBranch *)object;
        if (![uuid_ isEqual: otherBranch->uuid_ ]) return NO;
        if (![name_ isEqual: otherBranch->name_ ]) return NO;
        if (![stateTokens isEqual: otherBranch->stateTokens ]) return NO;
        if (![currentState isEqual: otherBranch->currentState ]) return NO;
        if (metadata != nil) {
            if (![metadata isEqual: otherBranch->metadata]) return NO;
        } else {
            if (otherBranch->metadata != nil) return NO;
        }
        return YES;
    }
    return NO;
}

- (NSUInteger) hash
{
    return [uuid_ hash] ^ [name_ hash] ^ [stateTokens hash] ^ [currentState hash] ^ [metadata hash];
}

- (void) _addCommit: (COPersistentRootStateToken *)aCommit
{
    assert(![stateTokens containsObject: aCommit]);
    [stateTokens addObject: aCommit];
}
- (void) _setCurrentState: (COPersistentRootStateToken *)aCommit
{
    assert([stateTokens containsObject: aCommit]);
    ASSIGN(currentState, aCommit);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[COBranch _branchWithPlist: [self _plist]] retain];
}

- (COBranch *) branchWithCurrentState
{
    COBranch *result = [[[COBranch alloc] initWithUUID: [COUUID UUID] name: [self name] initialState: [self currentState] metadata: [self metadata]] autorelease];
    return result;
}


@end
