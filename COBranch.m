#import <Foundation/Foundation.h>
#import "COBranch.h"
#import "COPersistentRootStateToken.h"
#import "COMacros.h"

NSString *kCOBranchUUID = @"COBranchUUID";
NSString *kCOBranchStateTokens = @"COBranchStateTokens";
NSString *kCOBranchCurrentStateToken = @"COBranchCurrentStateToken";
NSString *kCOBranchMetadata = @"COBranchMetadata";

// Metadata keys
NSString *kCOBranchName = @"COBranchName";

@implementation COBranch

- (id) initWithUUID: (COUUID *)aUUID
               name: (NSString *)name
       initialState: (COPersistentRootStateToken *)state
           metadata: (id)aMetadata
{
    self = [super init];
    uuid_ = [aUUID copy];
    stateTokens = [[NSMutableArray alloc] init];
    [stateTokens addObject: state];
    currentState = [state retain];
    metadata = [[NSMutableDictionary alloc] initWithDictionary: aMetadata];
    
    // FIXME: Overwrites any exiting name...
    [self setName: name];
    
    return self;
}

- (void) dealloc
{
    [uuid_ release];
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
    return [metadata objectForKey: kCOBranchName];
}
- (void) setName: (NSString *)aName
{
    [metadata setObject: [[aName copy] autorelease] forKey: kCOBranchName];
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
    
    [results setObject: [self _stateTokensPlist] forKey: kCOBranchStateTokens];
    
    [results setObject: [currentState plist] forKey: kCOBranchCurrentStateToken];

    [results setObject: [[metadata copy] autorelease ] forKey: kCOBranchMetadata];
    
    return results;
}
+ (COBranch *) _branchWithPlist: (id)plist
{
    COBranch *result = [[[COBranch alloc] init] autorelease];
    result->uuid_ = [[COUUID alloc] initWithString: [plist objectForKey: kCOBranchUUID]];
    result->stateTokens = [[self _stateTokensArrayFromPlist: [plist objectForKey: kCOBranchStateTokens]] mutableCopy];
    result->currentState = [[COPersistentRootStateToken tokenWithPlist: [plist objectForKey: kCOBranchCurrentStateToken]] retain];
    result->metadata = [[NSMutableDictionary alloc] initWithDictionary: [plist objectForKey: kCOBranchMetadata]];
    return result;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [self class]])
    {
        COBranch *otherBranch = (COBranch *)object;
        if (![uuid_ isEqual: otherBranch->uuid_ ]) return NO;
        if (![stateTokens isEqual: otherBranch->stateTokens ]) return NO;
        if (![currentState isEqual: otherBranch->currentState ]) return NO;
        if (![metadata isEqual: otherBranch->metadata]) return NO;

        return YES;
    }
    return NO;
}

- (NSUInteger) hash
{
    return [uuid_ hash] ^ [stateTokens hash] ^ [currentState hash] ^ [metadata hash];
}

- (void) _addCommit: (COPersistentRootStateToken *)aCommit
{
    if([stateTokens containsObject: aCommit]) {
        NSLog(@"_addCommit called with existing commit %@", aCommit);
    }
    [stateTokens addObject: aCommit];
}
- (void) _setCurrentState: (COPersistentRootStateToken *)aCommit
{
    if (![stateTokens containsObject: aCommit]) {
        NSLog(@"_setCurrentState called with non-existing commit %@", aCommit);
        [stateTokens addObject: aCommit];
    }
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

- (NSString *)description
{
    return [NSString stringWithFormat: @"<Branch %@>", [self UUID]];
}

@end
