#import "COPersistentRoot.h"
#import "COMacros.h"
#import "COBranch.h"

NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";
NSString *kCOPersistentRootBranchForUUID = @"COPersistentRootBranchForUUID";
NSString *kCOPersistentRootCurrentBranchUUID = @"COPersistentRootCurrentBranchUUID";
NSString *kCOPersistentRootMetadata = @"COPersistentRootMetadata";

@implementation COPersistentRoot

- (COUUID *) UUID
{
    return uuid;
}

/**
 * @return set of COBranch
 */
- (NSArray *) branches
{
    return [branches allValues];
}

- (COBranch *) currentBranch
{
    return [branches objectForKey: currentBranch];
}
- (COBranch *) branchForUUID: (COUUID *)aUUID
{
    return [branches objectForKey: aUUID];
}

- (NSDictionary *) metadata
{
    return metadata;
}

// @taskunit private

- (id) initWithUUID: (COUUID *)aUUID
           branches: (NSArray *)theBranches
      currentBranch: (COUUID *)aBranch
           metadata: (NSDictionary *)theMetadata
{
    self = [super init];
    uuid = [aUUID copy];
    branches = [[NSMutableDictionary alloc] init];
    for (COBranch *branch in theBranches)
    {
        COBranch *myCopy = [[branch mutableCopy] autorelease];
        [branches setObject: myCopy forKey: [myCopy UUID]];
    }
    currentBranch = [aBranch copy];
    metadata = [theMetadata copy];
    return self;
}


- (id) initWithPlist: (id)aPlist
{
    return [self initWithUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootUUID]]
                     branches: [[self class] branchesFromPlist: [aPlist objectForKey: kCOPersistentRootBranchForUUID]]
                currentBranch: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootCurrentBranchUUID]]
                     metadata: [aPlist objectForKey: kCOPersistentRootMetadata
                                ]];
}

- (void) dealloc
{
    [uuid release];
    [branches release];
    [currentBranch release];
    [metadata release];
    [super dealloc];
}

// persistence helper methods

- (id) branchesToPlist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    for (COUUID *key in branches)
    {
        COBranch *branch = [branches objectForKey: key];
        [results setObject: [branch _plist] forKey: [key stringValue]];
    }
    return results;
}

+ (NSArray*)branchesFromPlist: (id)aPlist
{
    NSMutableArray *results = [NSMutableArray array];
    for (NSString *key in aPlist)
    {
        COBranch *branch = [COBranch _branchWithPlist: [aPlist objectForKey: key]];
        [results addObject: branch];
    }
    return results;
}

- (id) plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    [results setObject: [uuid stringValue] forKey: kCOPersistentRootUUID];
    [results setObject: [self branchesToPlist] forKey: kCOPersistentRootBranchForUUID];
    
    [results setObject: [currentBranch stringValue] forKey: kCOPersistentRootCurrentBranchUUID];
    
    if (metadata != nil)
    {
        [results setObject: metadata forKey: kCOPersistentRootMetadata];
    }
    return results;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [self class]])
    {
        return [[self plist] isEqual: [object plist]];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [uuid hash] ^ [branches hash] ^ [currentBranch hash] ^ [metadata hash];
}



/**
 * Defines copy semantics for proots
 * TODO: paramaterize with the different types of copy
 // semantics is a ui question.
 // 1 extreme: only copies current state of current branch.
 // .or.
 // all states of all branches 
 */
- (COPersistentRoot *) persistentRootWithNewName
{
    return [self persistentRootCopyingBranch: [[self currentBranch] UUID]];
}

- (void) deleteBranch: (COUUID *)aUUID
{
    assert([branches objectForKey: aUUID] != nil);
    [branches removeObjectForKey: aUUID];
}
- (void) addBranch: (COBranch *)aBranch
{
    [branches setObject: aBranch forKey: [aBranch UUID]];
}
- (void) setCurrentBranch: (COUUID *)aUUID
{
    assert([branches objectForKey: aUUID] != nil);
    ASSIGN(uuid, aUUID);
}
- (COBranch *) _makeCopyOfBranch: (COUUID *)aUUID
{
    COUUID *newUUID = [COUUID UUID];
    COBranch *aCopy = [[[self branchForUUID: aUUID] mutableCopy] autorelease];
    [aCopy setUUID: newUUID];
    [branches setObject: aCopy forKey: newUUID];
    return aCopy;
}
- (COPersistentRoot *) persistentRootCopyingBranch: (COUUID *)aUUID
{
    COBranch *newBranch = [[self branchForUUID: aUUID] branchWithCurrentState];
    
    return [[[[self class] alloc] initWithUUID: [COUUID UUID]
                                      branches: [NSArray arrayWithObject: newBranch]
                                 currentBranch: [newBranch UUID]
                                      metadata: [self metadata]] autorelease];
}

@end
