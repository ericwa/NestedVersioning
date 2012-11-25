#import "COPersistentRootPlist.h"
#import "COMacros.h"
#import "CORevisionID.h"
#import "COMacros.h"

NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";

NSString *kCOPersistentRootRevisionIDs= @"COPersistentRootRevisionIDs";
NSString *kCOPersistentRootHeadRevisionIdForBranch= @"COPersistentRootHeadRevisionIdForBranch";
NSString *kCOPersistentRootTailRevisionIdForBranch= @"COPersistentRootTailRevisionIdForBranch";
NSString *kCOPersistentRootCurrentStateForBranch= @"COPersistentRootCurrentStateForBranch";

NSString *kCOPersistentRootCurrentBranchUUID = @"COPersistentRootCurrentBranchUUID";
NSString *kCOPersistentRootMetadata = @"COPersistentRootMetadata";

@implementation COPersistentRootPlist

- (id)      initWithUUID: (COUUID *)aUUID
             revisionIDs: (NSArray *)allRevisions
 headRevisionIdForBranch: (NSDictionary *)headForBranch
 tailRevisionIdForBranch: (NSDictionary *)tailForBranch
   currentStateForBranch: (NSDictionary *)stateForBranch
           currentBranch: (COUUID *)currentBranch
                metadata: (NSDictionary *)theMetadata
{
    NSParameterAssert([aUUID isKindOfClass: [COUUID class]]);
    NSParameterAssert([allRevisions isKindOfClass: [NSArray class]]);
    NSParameterAssert([headForBranch isKindOfClass: [NSDictionary class]]);
    NSParameterAssert([tailForBranch isKindOfClass: [NSDictionary class]]);
    NSParameterAssert([stateForBranch isKindOfClass: [NSDictionary class]]);
    NSParameterAssert([currentBranch isKindOfClass: [COUUID class]]);
    NSParameterAssert([theMetadata isKindOfClass: [NSDictionary class]]);
      
    SUPERINIT;
    
    uuid_ = [aUUID retain];
    revisionIDs_ = [[NSMutableArray alloc] initWithArray: allRevisions copyItems: YES];
    headRevisionIdForBranch_ = [[NSMutableDictionary alloc] initWithDictionary: headForBranch copyItems: YES];
    tailRevisionIdForBranch_ = [[NSMutableDictionary alloc] initWithDictionary: tailForBranch copyItems: YES];
    currentStateForBranch_ = [[NSMutableDictionary alloc] initWithDictionary: stateForBranch copyItems: YES];
    currentBranch_ = [currentBranch retain];
    metadata_ = [[NSMutableDictionary alloc] initWithDictionary: theMetadata copyItems: YES];
    
    return self;
}

- (id) initWithPersistentRootPlist: (COPersistentRootPlist *)aPlist
{
    return [self initWithUUID: aPlist->uuid_
                  revisionIDs: aPlist->revisionIDs_
      headRevisionIdForBranch: aPlist->headRevisionIdForBranch_
      tailRevisionIdForBranch: aPlist->tailRevisionIdForBranch_
        currentStateForBranch: aPlist->currentStateForBranch_
                currentBranch: aPlist->currentBranch_
                     metadata: aPlist->metadata_];
}


- (id)copyWithZone:(NSZone *)zone
{
    return [[COPersistentRootPlist alloc] initWithPersistentRootPlist: self];
}

- (void) dealloc
{
    [uuid_ release];
    [revisionIDs_ release];
    [headRevisionIdForBranch_ release];
    [tailRevisionIdForBranch_ release];
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
    return [currentStateForBranch_ allKeys];
}

- (NSArray *) revisionIDs
{
    return revisionIDs_;
}
- (void) addRevisionID: (CORevisionID *)aRevision
{
    [revisionIDs_ addObject: aRevision];
}

- (COUUID *) currentBranchUUID
{
    return currentBranch_;
}
- (void) setCurrentBranchUUID: (COUUID *)aUUID
{
    NSParameterAssert([aUUID isKindOfClass: [COUUID class]]);
    if (nil == [currentStateForBranch_ objectForKey: aUUID])
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"uuid %@ not a branch", aUUID];
    }
    ASSIGN(currentBranch_, aUUID);
}

- (CORevisionID *)headRevisionIdForBranch: (COUUID *)aBranch
{
    return [headRevisionIdForBranch_ objectForKey: aBranch];
}
- (void)setHeadRevisionId: (CORevisionID *)aRevision
                forBranch: (COUUID *)aUUID
{
    [headRevisionIdForBranch_ setObject: aRevision
                                 forKey: aUUID];
}

- (CORevisionID *)tailRevisionIdForBranch: (COUUID *)aBranch
{
    return [tailRevisionIdForBranch_ objectForKey: aBranch];
}
- (void)setTailRevisionId: (CORevisionID *)aRevision
                forBranch: (COUUID *)aUUID
{
    [tailRevisionIdForBranch_ setObject: aRevision forKey: aUUID];
}

- (CORevisionID *)currentStateForBranch: (COUUID *)aBranch
{
    return [currentStateForBranch_ objectForKey: aBranch];
}
- (void)setCurrentState: (CORevisionID *)aRevision
              forBranch: (COUUID *)aUUID
{
    [currentStateForBranch_ setObject: aRevision forKey: aUUID];
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
    return [self initWithUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootUUID]]
                  revisionIDs: stateTokensFromPlist([aPlist objectForKey: kCOPersistentRootRevisionIDs])
      headRevisionIdForBranch: UUIDToRevisionIdMapFromPlist([aPlist objectForKey: kCOPersistentRootHeadRevisionIdForBranch])
      tailRevisionIdForBranch: UUIDToRevisionIdMapFromPlist([aPlist objectForKey: kCOPersistentRootTailRevisionIdForBranch])
        currentStateForBranch: UUIDToRevisionIdMapFromPlist([aPlist objectForKey: kCOPersistentRootCurrentStateForBranch])
                currentBranch: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootUUID]]
                     metadata: [aPlist objectForKey: kCOPersistentRootMetadata]];
}

- (id) plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [results setObject: [uuid_ stringValue] forKey: kCOPersistentRootUUID];
    [results setObject: plistFromStateTokens(revisionIDs_) forKey: kCOPersistentRootRevisionIDs];
    [results setObject: plistFromUUIDToRevisionIdMap(headRevisionIdForBranch_) forKey: kCOPersistentRootHeadRevisionIdForBranch];
    [results setObject: plistFromUUIDToRevisionIdMap(tailRevisionIdForBranch_) forKey: kCOPersistentRootTailRevisionIdForBranch];
    [results setObject: plistFromUUIDToRevisionIdMap(currentStateForBranch_) forKey: kCOPersistentRootCurrentStateForBranch];
    [results setObject: [currentBranch_ stringValue] forKey: kCOPersistentRootCurrentBranchUUID];
    [results setObject: metadata_ forKey: kCOPersistentRootMetadata];
    return results;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [self class]])
    {
        COPersistentRootPlist *other = (COPersistentRootPlist *)object;
        return [uuid_ isEqual: other->uuid_]
        && [revisionIDs_ isEqual: other->revisionIDs_]
        && [headRevisionIdForBranch_ isEqual: other->headRevisionIdForBranch_]
        && [tailRevisionIdForBranch_ isEqual: other->tailRevisionIdForBranch_]
        && [currentStateForBranch_ isEqual: other->currentStateForBranch_]
        && [currentBranch_ isEqual: other->currentBranch_]
        && [metadata_ isEqual: other->metadata_];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [uuid_ hash]
    ^ [revisionIDs_ hash]
    ^ [headRevisionIdForBranch_ hash]
    ^ [tailRevisionIdForBranch_ hash]
    ^ [currentStateForBranch_ hash]
    ^ [currentBranch_ hash]
    ^ [metadata_ hash];
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
        [result addObject: [CORevisionID tokenWithPlist: plist]];
    }
    return result;
}
                                                
static NSDictionary *plistFromUUIDToRevisionIdMap(NSDictionary *map)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (COUUID *key in map)
    {
        [result setObject: [(CORevisionID*)[map objectForKey: key] plist]
                   forKey: [key stringValue]];
    }
    return result;
}
                                            
static NSDictionary *UUIDToRevisionIdMapFromPlist(NSDictionary *map)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *key in map)
    {
        [result setObject: [CORevisionID tokenWithPlist: [map objectForKey: key]]
                   forKey: [COUUID UUIDWithString: key]];
    }
    return result;
}
                                                
@end
