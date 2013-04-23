#import "COPersistentRootState.h"
#import "COMacros.h"
#import "CORevisionID.h"
#import "COMacros.h"
#import "COBranchState.h"
#import "COUUID.h"

NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";

NSString *kCOPersistentRootBranchForUUID= @"COPersistentRootBranchForUUID";
NSString *kCOPersistentRootCurrentBranchUUID = @"COPersistentRootCurrentBranchUUID";
NSString *kCOPersistentRootMainBranchUUID = @"COPersistentRootMainBranchUUID";
NSString *kCOPersistentRootMetadata = @"COPersistentRootMetadata";

@implementation COPersistentRootState

@synthesize UUID = uuid_;
@synthesize metadata = metadata_;
@synthesize currentBranchUUID = currentBranch_;
@synthesize mainBranchUUID = mainBranch_;
@synthesize branchForUUID = branchForUUID_;

- (id) initWithUUID: (COUUID *)aUUID
      branchForUUID: (NSDictionary *)branchForUUID
  currentBranchUUID: (COUUID *)currentBranch
     mainBranchUUID: (COUUID *)mainBranch
           metadata: (NSDictionary *)theMetadata
{
    NSParameterAssert([aUUID isKindOfClass: [COUUID class]]);

    SUPERINIT;
    
    uuid_ = [aUUID retain];
    branchForUUID_ = [[NSMutableDictionary alloc] initWithDictionary: branchForUUID];

    [self setCurrentBranchUUID: currentBranch];
    [self setMainBranchUUID: mainBranch];
    [self setMetadata: theMetadata];
    
    return self;
}

- (id) initWithPersistentRootPlist: (COPersistentRootState *)aPlist
{
    return [self initWithUUID: aPlist->uuid_
                branchForUUID: aPlist->branchForUUID_
            currentBranchUUID: aPlist->currentBranch_
               mainBranchUUID: aPlist->mainBranch_
                     metadata: aPlist->metadata_];
}


- (id)copyWithZone:(NSZone *)zone
{
    return [[COPersistentRootState alloc] initWithPersistentRootPlist: self];
}

- (void) dealloc
{
    [uuid_ release];
    [branchForUUID_ release];
    [currentBranch_ release];
    [mainBranch_ release];
    [metadata_ release];
    [super dealloc];
}

- (NSSet *) branchUUIDs
{
    return [NSSet setWithArray: [branchForUUID_ allKeys]];
}

- (COBranchState *)branchPlistForUUID: (COUUID *)aUUID
{
    return [branchForUUID_ objectForKey: aUUID];
}
- (COBranchState *)currentBranchState
{
    return [self branchPlistForUUID: [self currentBranchUUID]];
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
                branchForUUID: UUIDToBranchMapFromPlist([aPlist objectForKey: kCOPersistentRootBranchForUUID])
            currentBranchUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootCurrentBranchUUID]]
               mainBranchUUID: [COUUID UUIDWithString: [aPlist objectForKey: kCOPersistentRootMainBranchUUID]]
                     metadata: [aPlist objectForKey: kCOPersistentRootMetadata]];
}

- (id) plist
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [results setObject: [uuid_ stringValue] forKey: kCOPersistentRootUUID];
    [results setObject: plistFromUUIDToBranchMap(branchForUUID_) forKey: kCOPersistentRootBranchForUUID];
    [results setObject: [currentBranch_ stringValue] forKey: kCOPersistentRootCurrentBranchUUID];
    [results setObject: [mainBranch_ stringValue] forKey: kCOPersistentRootMainBranchUUID];
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
        && [branchForUUID_ isEqual: other->branchForUUID_]
        && [currentBranch_ isEqual: other->currentBranch_]
        && [mainBranch_ isEqual: other->mainBranch_]
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
