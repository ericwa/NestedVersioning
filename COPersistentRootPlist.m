#import "COPersistentRootPlist.h"
#import "COMacros.h"
#import "COPersistentRootStateToken.h"

NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";
NSString *kCOPersistentRootStateTokensForBranch = @"COPersistentRootStateTokensForBranch";
NSString *kCOPersistentCurrentStateForBranch = @"COPersistentCurrentStateForBranch";
NSString *kCOPersistentRootCurrentBranchUUID = @"COPersistentRootCurrentBranchUUID";
NSString *kCOPersistentRootMetadata = @"COPersistentRootMetadata";

@implementation COPersistentRootPlist

- (id)      initWithUUID: (COUUID *)aUUID
    stateTokensForBranch: (NSDictionary *)state
   currentStateForBranch: (NSDictionary *)stateForBranch
           currentBranch: (COUUID *)currentBranch
                metadata: (NSDictionary *)theMetadata
{
    NILARG_EXCEPTION_TEST(aUUID);
    NILARG_EXCEPTION_TEST(state);
    NILARG_EXCEPTION_TEST(stateForBranch);
    NILARG_EXCEPTION_TEST(currentBranch);
    
    if (![aUUID isKindOfClass: [COUUID class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected UUID"];
    }
    if (![currentBranch isKindOfClass: [COUUID class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected UUID"];
    }
    for (NSArray *stateTokens in [state allValues])
    {
        for (COPersistentRootStateToken *token in stateTokens)
        {
            if (![token isKindOfClass: [COPersistentRootStateToken class]])
            {
                [NSException raise: NSInvalidArgumentException format: @"expected COPersistentRootStateToken"];
            }
        }
    }
    for (COPersistentRootStateToken *token in [stateForBranch allValues])
    {
        if (![token isKindOfClass: [COPersistentRootStateToken class]])
        {
            [NSException raise: NSInvalidArgumentException format: @"expected COPersistentRootStateToken"];
        }
    }
    
    SUPERINIT;
    
    uuid_ = [aUUID retain];
    stateTokensForBranch_ = [[NSMutableDictionary alloc] initWithDictionary: state copyItems: YES];
    currentStateForBranch_ = [[NSMutableDictionary alloc] initWithDictionary: stateForBranch copyItems: YES];
    currentBranch_ = [currentBranch retain];
    [self setMetadata: theMetadata];
    
    return self;
}

- (void) dealloc
{
    [uuid_ release];
    [stateTokensForBranch_ release];
    [currentStateForBranch_ release];
    [currentBranch_ release];
    [metadata_ release];
    [super dealloc];
}

- (COUUID *) UUID
{
    return uuid_;
}

- (NSArray *) branchUUIDs
{
    return [stateTokensForBranch_ allKeys];
}

- (COUUID *) currentBranchUUID
{
    return currentBranch_;
}
- (void) setCurrentBranchUUID: (COUUID *)aUUID
{
    if (![aUUID isKindOfClass: [COUUID class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected UUID"];
    }
    if (nil == [stateTokensForBranch_ objectForKey: aUUID])
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"uuid %@ not a branch", aUUID];
    }
    ASSIGN(currentBranch_, aUUID);
}

- (NSArray *) stateTokensForBranch: (COUUID *)aBranch
{
    return [stateTokensForBranch_ objectForKey: aBranch];
}
- (void) addStateToken: (COPersistentRootStateToken *)aToken
             forBranch: (COUUID *)aBranch
{
    if (![aToken isKindOfClass: [COPersistentRootStateToken class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected COPersistentRootStateToken"];
    }
    if (nil == [stateTokensForBranch_ objectForKey: aBranch])
    {
        [stateTokensForBranch_ setObject: [NSArray array]
                                  forKey: aBranch];
        [currentStateForBranch_ setObject: aToken
                                   forKey: aBranch];
    }
    
    [stateTokensForBranch_ setObject: [[stateTokensForBranch_ objectForKey: aBranch] arrayByAddingObject: aToken]
                              forKey: aBranch];
}

- (COPersistentRootStateToken *)currentStateForBranch: (COUUID *)aBranch
{
    return [currentStateForBranch_ objectForKey: aBranch];
}
- (void) setCurrentState: (COPersistentRootStateToken *)aState
               forBranch: (COUUID *)aBranch
{
    if (![aState isKindOfClass: [COPersistentRootStateToken class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected COPersistentRootStateToken"];
    }
    if (nil == [stateTokensForBranch_ objectForKey: aBranch])
    {
        [stateTokensForBranch_ setObject: [NSArray array]
                                  forKey: aBranch];
    }
    [currentStateForBranch_ setObject: aState forKey: aBranch];
}

- (NSDictionary *) metadata
{
    return metadata_;
}
- (void) setMetadata: (NSDictionary *)theMetadata
{
    ASSIGN(metadata_, [NSDictionary dictionaryWithDictionary: theMetadata]);
}

// Plist import/export

- (id) initWithPlist: (id)aPlist
{
    COUUID *uuid = [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootUUID]];
    COUUID *currentBranch = [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootCurrentBranchUUID]];
    NSDictionary *metadata = [aPlist objectForKey: kCOPersistentRootMetadata];
    
    NSDictionary *stateTokensForBranchPlist = [aPlist objectForKey: kCOPersistentRootStateTokensForBranch];
    NSDictionary *currentStateForBranchPlist = [aPlist objectForKey: kCOPersistentCurrentStateForBranch];
    
    NSMutableDictionary *stateTokensForBranch = [NSMutableDictionary dictionary];
    NSMutableDictionary *currentStateForBranch = [NSMutableDictionary dictionary];
    for (NSString *branchUUIDString in [stateTokensForBranchPlist allKeys])
    {
        COUUID *branchUUID = [COUUID UUIDWithString: branchUUIDString];
        
        NSArray *stateTokens = stateTokensFromPlist([stateTokensForBranchPlist objectForKey: branchUUIDString]);
        COPersistentRootStateToken *currentState = [COPersistentRootStateToken tokenWithPlist:
                                                    [currentStateForBranchPlist objectForKey: branchUUIDString]];
        
        [stateTokensForBranch setObject: stateTokens
                                 forKey: branchUUID];
        [currentStateForBranch setObject: currentState
                                  forKey: branchUUID];
    }

    return [self initWithUUID: uuid
         stateTokensForBranch: stateTokensForBranch
        currentStateForBranch: currentStateForBranch
                currentBranch: currentBranch
                     metadata: metadata];
}

- (id) plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [results setObject: [uuid_ stringValue] forKey: kCOPersistentRootUUID];
    [results setObject: [currentBranch_ stringValue] forKey: kCOPersistentRootCurrentBranchUUID];
    [results setObject: metadata_ forKey: kCOPersistentRootMetadata];
            
    NSMutableDictionary *stateTokensForBranchPlist = [NSMutableDictionary dictionary];
    NSMutableDictionary *currentStateForBranchPlist = [NSMutableDictionary dictionary];
    for (COUUID *branchUUID in [self branchUUIDs])
    {
        NSArray *stateTokensPlist = plistFromStateTokens([self stateTokensForBranch: branchUUID]);
        id currentStatePlist = [[self currentStateForBranch: branchUUID] plist];
        
        [stateTokensForBranchPlist setObject: stateTokensPlist
                                      forKey: [branchUUID stringValue]];
        [currentStateForBranchPlist setObject: currentStatePlist
                                       forKey: [branchUUID stringValue]];
    }
    [results setObject: stateTokensForBranchPlist forKey: kCOPersistentRootStateTokensForBranch];
    [results setObject: currentStateForBranchPlist forKey: kCOPersistentCurrentStateForBranch];
        
    return results;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [self class]])
    {
        COPersistentRootPlist *other = (COPersistentRootPlist *)object;
        return [uuid_ isEqual: other->uuid_]
            && [stateTokensForBranch_ isEqual: other->stateTokensForBranch_]
            && [currentStateForBranch_ isEqual: other->currentStateForBranch_]
            && [currentBranch_ isEqual: other->currentBranch_]
            && [metadata_ isEqual: other->metadata_];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [uuid_ hash]
        ^ [stateTokensForBranch_ hash]
        ^ [currentStateForBranch_ hash]
        ^ [currentBranch_ hash]
        ^ [metadata_ hash];
}

static NSArray *plistFromStateTokens(NSArray *stateTokens)
{
    NSMutableArray *result = [NSMutableArray array];
    for (COPersistentRootStateToken *token in stateTokens)
    {
        [result addObject: [token plist]];
    }
    return result;
}

static NSArray *stateTokensFromPlist(NSArray *array)
{
    NSMutableArray *result = [NSMutableArray array];
    for (id plist in array)
    {
        [result addObject: [COPersistentRootStateToken tokenWithPlist: plist]];
    }
    return result;
}

@end
