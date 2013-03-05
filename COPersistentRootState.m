#import "COPersistentRootState.h"
#import "COMacros.h"
#import "CORevisionID.h"
#import "COMacros.h"
#import "COBranchState.h"
#import "COUUID.h"

NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";

NSString *kCOPersistentRootRevisionIDs= @"COPersistentRootRevisionIDs";
NSString *kCOPersistentRootBranchForUUID= @"COPersistentRootBranchForUUID";
NSString *kCOPersistentRootCurrentBranchUUID = @"COPersistentRootCurrentBranchUUID";
NSString *kCOPersistentRootMetadata = @"COPersistentRootMetadata";

@implementation COPersistentRootState

@synthesize UUID = uuid_;
@synthesize metadata = metadata_;
@synthesize currentBranchUUID = currentBranch_;

- (id) initWithUUID: (COUUID *)aUUID
        revisionIDs: (NSArray *)allRevisions
      branchForUUID: (NSDictionary *)branchForUUID
  currentBranchUUID: (COUUID *)currentBranch
           metadata: (NSDictionary *)theMetadata
{
    NSParameterAssert([aUUID isKindOfClass: [COUUID class]]);

    SUPERINIT;
    
    uuid_ = [aUUID retain];
    revisionIDs_ = [[NSMutableArray alloc] initWithArray: allRevisions copyItems: YES];
    branchForUUID_ = [[NSMutableDictionary alloc] initWithDictionary: branchForUUID copyItems: YES];

    [self setCurrentBranchUUID: currentBranch];
    [self setMetadata: theMetadata];
    
    return self;
}

- (id) initWithPersistentRootPlist: (COPersistentRootState *)aPlist
{
    return [self initWithUUID: aPlist->uuid_
                  revisionIDs: aPlist->revisionIDs_
                branchForUUID: aPlist->branchForUUID_
            currentBranchUUID: aPlist->currentBranch_            
                     metadata: aPlist->metadata_];
}


- (id)copyWithZone:(NSZone *)zone
{
    return [[COPersistentRootState alloc] initWithPersistentRootPlist: self];
}

- (void) dealloc
{
    [uuid_ release];
    [revisionIDs_ release];
    [branchForUUID_ release];
    [currentBranch_ release];
    [metadata_ release];
    [super dealloc];
}

- (NSSet *) branchUUIDs
{
    return [NSSet setWithArray: [branchForUUID_ allKeys]];
}

- (NSArray *) revisionIDs
{
    return revisionIDs_;
}
- (void) addRevisionID: (CORevisionID *)aRevision
{
    [revisionIDs_ addObject: aRevision];
}

- (COBranchState *)branchPlistForUUID: (COUUID *)aUUID
{
    return [branchForUUID_ objectForKey: aUUID];
}
- (void)setBranchPlist: (COBranchState *)aBranch
               forUUID: (COUUID *)aUUID
{
    [branchForUUID_ setObject: aBranch forKey: aUUID];
}
- (void)removeBranchForUUID: (COUUID *)aUUID
{
    [branchForUUID_ removeObjectForKey: aUUID];
}

// Plist import/export

- (id) initWithPlist: (id)aPlist
{
    return [self initWithUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootUUID]]
                  revisionIDs: stateTokensFromPlist([aPlist objectForKey: kCOPersistentRootRevisionIDs])
                branchForUUID: UUIDToBranchMapFromPlist([aPlist objectForKey: kCOPersistentRootBranchForUUID])
            currentBranchUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootCurrentBranchUUID]]
                     metadata: [aPlist objectForKey: kCOPersistentRootMetadata]];
}

- (id) plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [results setObject: [uuid_ stringValue] forKey: kCOPersistentRootUUID];
    [results setObject: plistFromStateTokens(revisionIDs_) forKey: kCOPersistentRootRevisionIDs];
    [results setObject: plistFromUUIDToBranchMap(branchForUUID_) forKey: kCOPersistentRootBranchForUUID];
    [results setObject: [currentBranch_ stringValue] forKey: kCOPersistentRootCurrentBranchUUID];
    if (metadata_ != nil)
    {
        [results setObject: metadata_ forKey: kCOPersistentRootMetadata];
    }
    return results;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [self class]])
    {
        COPersistentRootState *other = (COPersistentRootState *)object;
        return [uuid_ isEqual: other->uuid_]
        && [revisionIDs_ isEqual: other->revisionIDs_]
        && [branchForUUID_ isEqual: other->branchForUUID_]
        && [currentBranch_ isEqual: other->currentBranch_]
        && [metadata_ isEqual: other->metadata_];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [uuid_ hash];
}

- (NSString *) description
{
    return [[self plist] description];
}

static NSArray *plistFromStateTokens(NSArray *stateTokens)
{
    NSMutableArray *result = [NSMutableArray array];
    for (CORevisionID *token in stateTokens)
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
        [result addObject: [CORevisionID revisionIDWithPlist: plist]];
    }
    return result;
}
static NSDictionary *plistFromUUIDToBranchMap(NSDictionary *map)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (COUUID *key in map)
    {
        [result setObject: [[map objectForKey: key] plist]
                   forKey: [key stringValue]];
    }
    return result;
}

static NSDictionary *UUIDToBranchMapFromPlist(NSDictionary *map)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *key in map)
    {
        [result setObject: [[[COBranchState alloc] initWithPlist: [map objectForKey: key]] autorelease]
                   forKey: [COUUID UUIDWithString: key]];
    }
    return result;
}

@end
