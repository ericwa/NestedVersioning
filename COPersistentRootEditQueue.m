#import "COPersistentRootEditQueue.h"
#import "COStoreEditQueue.h"
#import "COBranchEditQueue.h"
#import "COMacros.h"
#import "COPersistentRootPlist.h"
#import "COEditQueuePrivate.h"
#import "COSQLiteStore.h"

@implementation COPersistentRootEditQueue

NSString *kCOPersistentRootName = @"COPersistentRootName";

- (id)initWithStoreEditQueue: (COStoreEditQueue *)aRootStore
              persistentRoot: (COPersistentRootPlist *)metadata
{
    SUPERINIT;
    rootStore_ = aRootStore;
    savedState_ = [[COPersistentRootPlist alloc] initWithPersistentRootPlist: metadata];
    branchEditQueueForUUID_ = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) dealloc
{
    [savedState_ release];
    [branchEditQueueForUUID_ release];
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
    BOOL ok = [[self store] setMetadata: theMetadata forPersistentRoot: [self UUID]];
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

- (NSArray *) branchUUIDs
{
    return [savedState_ branchUUIDs];
}

- (COUUID *) currentBranchUUID
{
    return [savedState_ currentBranchUUID];
}

- (void) setCurrentBranchUUID: (COUUID *)aUUID
{
    BOOL ok = [[self store] setCurrentBranch: aUUID forPersistentRoot: [self UUID]];
    assert(ok);
    // FIXME: Throw exception if not ok?
    [savedState_ setCurrentBranchUUID: aUUID];
    
    if (currentBranchEditQueue_ != nil)
    {
        [currentBranchEditQueue_ setBranch: aUUID];
    }
}

- (NSArray *) allCommits
{
    return [savedState_ revisionIDs];
}

- (COBranchEditQueue *) createBranchAtRevision: (CORevisionID *)aRevision
                                    setCurrent: (BOOL)setCurrent
{
    COUUID *aBranch = [[self store] createBranchWithInitialRevision: aRevision
                                                               setCurrent: setCurrent forPersistentRoot: [self UUID]];
    
    // FIXME: Overly coarse
    savedState_ = [[self store] persistentRootWithUUID: [self UUID]];
    
    return [self contextForEditingBranchWithUUID: aBranch];
}

- (COBranchEditQueue *) contextForEditingCurrentBranch
{
    if (currentBranchEditQueue_ == nil)
    {
        currentBranchEditQueue_ = [[COBranchEditQueue alloc] initWithPersistentRoot: self
                                                                             branch: [self currentBranchUUID]
                                                                 trackCurrentBranch: YES];
        
    }
    return currentBranchEditQueue_;
}

- (COBranchEditQueue *) contextForEditingBranchWithUUID: (COUUID *)aUUID
{
    COBranchEditQueue *cached = [branchEditQueueForUUID_ objectForKey: aUUID];
    if (cached != nil)
    {
        return cached;
    }
    
    if ([[savedState_ branchUUIDs] containsObject: aUUID])
    {
        COBranchEditQueue *branch = [[[COBranchEditQueue alloc] initWithPersistentRoot: self
                                                                                branch: aUUID
                                                                    trackCurrentBranch: NO] autorelease];
        [branchEditQueueForUUID_ setObject: branch forKey: aUUID];        
        return branch;
    }
    
    // FIXME: not really an error, just for debugging
    assert(0);
    return nil;
}

- (COPersistentRootPlist *) savedState
{
    return savedState_;
}

@end

@implementation COPersistentRootEditQueue (Private)

- (COSQLiteStore *) store
{
    return [rootStore_ store];
}

@end
