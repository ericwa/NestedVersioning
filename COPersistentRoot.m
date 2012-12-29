#import "COPersistentRoot.h"
#import "COStore.h"
#import "COBranch.h"
#import "COMacros.h"
#import "COPersistentRootState.h"
#import "COPersistentRootPrivate.h"
#import "COSQLiteStore.h"


@implementation COPersistentRoot (Private)

- (id)initWithStoreEditQueue: (COStore *)aRootStore
              persistentRoot: (COPersistentRootState *)metadata
{
    SUPERINIT;
    rootStore_ = aRootStore;
    savedState_ = [[COPersistentRootState alloc] initWithPersistentRootPlist: metadata];
    branchForUUID_ = [[NSMutableDictionary alloc] init];
    return self;
}

- (COSQLiteStore *) store
{
    return [rootStore_ store];
}

- (COPersistentRootState *) savedState
{
    return savedState_;
}

@end

@implementation COPersistentRoot

NSString *kCOPersistentRootName = @"COPersistentRootName";

- (void) dealloc
{
    [savedState_ release];
    [branchForUUID_ release];
    [super dealloc];
}

- (COUUID *) UUID
{
    return [savedState_ UUID];
}

// metadata & convenience

- (NSDictionary *) metadata
{
    NSDictionary *result = [savedState_ metadata];
    if (result == nil)
    {
        return [NSDictionary dictionary];
    }
    return result;
}
- (void) setMetadata: (NSDictionary *)theMetadata
{
    BOOL ok = [[self store] setMetadata: theMetadata
                      forPersistentRoot: [self UUID]
                      operationMetadata: nil];
    assert(ok);
    // FIXME: Throw exception if not ok?
    [savedState_ setMetadata: theMetadata];
}

- (NSString *)name
{
    return [[self metadata] objectForKey: kCOPersistentRootName];
}
- (void) setName: (NSString *)aName
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self metadata]];
    [dict setObject: aName forKey: kCOPersistentRootName];
    [self setMetadata: dict];
}

// branches

- (NSSet *) branches
{
    NSMutableSet *result = [NSMutableSet set];
    for (COUUID *uuid in [savedState_ branchUUIDs])
    {
        [result addObject: [self branchWithUUID: uuid]];
    }
    return [NSSet setWithSet: result];
}

- (NSArray *) revisionIDs
{
    return [savedState_ revisionIDs];
}

- (COBranch *) createBranchAtRevision: (CORevisionID *)aRevision
                                    setCurrent: (BOOL)setCurrent
{
    COUUID *aBranch = [[self store] createBranchWithInitialRevision: aRevision
                                                         setCurrent: setCurrent
                                                  forPersistentRoot: [self UUID]
                                                  operationMetadata: nil];
    
    // FIXME: Overly coarse
    ASSIGN(savedState_, [[self store] persistentRootWithUUID: [self UUID]]);
    
    // Update current branch edit queue
    if (currentBranch_ != nil)
    {
        [currentBranch_ setBranch: aBranch];
    }
    
    return [self branchWithUUID: aBranch];
}

- (COBranch *) currentBranch
{
    if (currentBranch_ == nil)
    {
        currentBranch_ = [[COBranch alloc] initWithPersistentRoot: self
                                                           branch: [savedState_ currentBranchUUID]
                                               trackCurrentBranch: YES];
        
    }
    return currentBranch_;
}

- (void) setCurrentBranch: (COBranch *)aBranch
{
    BOOL ok = [[self store] setCurrentBranch: [aBranch UUID]
                           forPersistentRoot: [self UUID]
                           operationMetadata: nil];
    assert(ok);
    // FIXME: Throw exception if not ok?
    [savedState_ setCurrentBranchUUID: [aBranch UUID]];
    
    if (currentBranch_ != nil)
    {
        [currentBranch_ setBranch: [aBranch UUID]];
    }
}

- (void) removeBranch: (COBranch *)aBranch
{
    NSParameterAssert(![[self currentBranch] isEqual: aBranch]);
    
    BOOL ok = [[self store] deleteBranch: [aBranch UUID]
                        ofPersistentRoot: [self UUID]
                       operationMetadata: nil];
    assert(ok);
    // FIXME: Throw exception if not ok?
    
    [savedState_ removeBranchForUUID: [aBranch UUID]];
}

- (COBranch *) branchWithUUID: (COUUID *)aUUID
{
    COBranch *cached = [branchForUUID_ objectForKey: aUUID];
    if (cached != nil)
    {
        return cached;
    }
    
    if ([[savedState_ branchUUIDs] containsObject: aUUID])
    {
        COBranch *branch = [[[COBranch alloc] initWithPersistentRoot: self
                                                                                branch: aUUID
                                                                    trackCurrentBranch: NO] autorelease];
        [branchForUUID_ setObject: branch forKey: aUUID];        
        return branch;
    }
    
    // FIXME: not really an error, just for debugging
    assert(0);
    return nil;
}

- (NSArray *) operationLog
{
    return [[self store] operationLogForPersistentRoot: [self UUID]];
}

@end
