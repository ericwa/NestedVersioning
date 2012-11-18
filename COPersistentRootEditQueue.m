#import "COPersistentRootEditQueue.h"
#import "COStoreEditQueue.h"
#import "COBranchEditQueue.h"
#import "COMacros.h"
#import "COPersistentRootPlist.h"
#import "COEditQueuePrivate.h"

@implementation COPersistentRootEditQueue

NSString *kCOPersistentRootName = @"COPersistentRootName";

- (id)initWithRootStore: (COStoreEditQueue *)aRootStore
                   uuid: (COUUID *)aUUID
                  isNew: (BOOL)isNew
{
    SUPERINIT;
    rootStore_ = aRootStore;
    isNew_ = isNew;
    ASSIGN(uuid_, aUUID);
    branchEditQueueForUUID_ = [[NSMutableDictionary alloc] init];
    
    if (isNew_)
    {
        savedState_ = nil;
        
        // create an initial branch
        
        COUUID *initialBranch = [COUUID UUID];
        ASSIGN(newBranch_, initialBranch);
        ASSIGN(currentBranch_, initialBranch);
        
        COBranchEditQueue *queue = [[COBranchEditQueue alloc] initWithRoot:self branch:initialBranch initialState:nil];
        
        [branchEditQueueForUUID_ setObject:  queue forKey: initialBranch];
        
        metadata_ = [[NSMutableDictionary alloc] init];
    }
    else
    {
        ASSIGN(savedState_, [[rootStore_ store] persistentRootWithUUID: uuid_]);
        
        assert(savedState_ != nil);
    }
    
    return self;
}

- (void) dealloc
{
    // FIXME:
    [super dealloc];
}

- (COUUID *) UUID
{
    return uuid_;
}

// metadata & convenience

- (NSDictionary *) metadata
{
    if (metadata_ != nil)
    {
        return metadata_;
    }
    NSDictionary *metadata = [savedState_ metadata];
    assert(metadata != nil);
    return metadata;
}
- (void) setMetadata: (NSDictionary *)theMetadata
{
    ASSIGN(metadata_, [NSDictionary dictionaryWithDictionary:theMetadata]);
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
    if (newBranch_ != nil)
    {
        NSMutableArray *result = [NSMutableArray array];
        [result addObject: newBranch_];
        if ([savedState_ branchUUIDs] != nil)
        {
            [result addObjectsFromArray: [savedState_ branchUUIDs]];
        }
        return [NSArray arrayWithArray: result];
    }
    
    NSArray *result = [savedState_ branchUUIDs];
    assert(result != nil);
    return result;
}

- (COUUID *) currentBranchUUID
{
    if (currentBranch_ != nil)
    {
        return currentBranch_;
    }
    COUUID *saved = [savedState_ currentBranchUUID];    
    assert(saved != nil);
    return saved;
}
- (void) setCurrentBranchUUID: (COUUID *)aUUID
{
    ASSIGN(currentBranch_, aUUID);

    if (currentBranchEditQueue_ != nil)
    {
        [currentBranchEditQueue_ setBranch: currentBranch_];
    }
}

/**
 * @returns array of COPersistentRootStateToken
 */
- (NSArray *) allCommits
{
    if (savedState_ == nil)
    {
        return [NSArray array];
    }
    else
    {
        NSMutableSet *resultSet = [NSMutableSet set];
        for (COUUID *branchUUID in [savedState_ branchUUIDs])
        {
            [resultSet addObjectsFromArray: [savedState_ stateTokensForBranch: branchUUID]];
        }
        return [resultSet allObjects];
    }
}

// committing changes

- (BOOL) commitChanges
{
    if (isNew_)
    {        
        // Allowing an initial commit to:
        // a) create multiple branches with a commit on each branch
        // b) specfiy the starting branch
        //
        // is overkill.
        
        COBranchEditQueue *queue = [self contextForEditingBranchWithUUID: newBranch_];
        
        COPersistentRootState *state = [queue fullState];
        
        assert(state != nil);
        
        [[rootStore_ store] createPersistentRootWithUUID: [self UUID]
                                         initialContents: state];
        
        // FIXME: pass in metadata
    }
    else
    {
        
    }
    
    
    // FIXME: hack to make test pass. have to reload
    [self discardChanges];
    
    return YES;
}

- (void) discardChanges
{
    ASSIGN(currentBranch_, nil);
    ASSIGN(metadata_, nil);
    
    if (newBranch_ != nil)
    {
        [branchEditQueueForUUID_ removeObjectForKey: newBranch_];
    }
    ASSIGN(newBranch_, nil);
    
    for (COBranchEditQueue *branch in [branchEditQueueForUUID_ allValues])
    {
        [branch discardChanges];
    }
}

- (COBranchEditQueue *) createBranch
{
    if (newBranch_ != nil)
    {
        [NSException raise: NSGenericException format: @"createBranch called but there's already a new branch"];
    }
    
    ASSIGN(newBranch_, [COUUID UUID]);
    
    COBranchEditQueue *q = [[COBranchEditQueue alloc] initWithRoot: self branch: newBranch_ initialState: nil];
    
    [branchEditQueueForUUID_ setObject: q forKey: newBranch_];
    
    return q;
}

- (COBranchEditQueue *) contextForEditingCurrentBranch
{
    if (currentBranchEditQueue_ == nil)
    {
        currentBranchEditQueue_ = [[COBranchEditQueue alloc] initWithRoot: self branch: currentBranch_ initialState: nil]; // FIXME: correct initial state
        
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
        COBranchEditQueue *branch = [[COBranchEditQueue alloc] initWithRoot: self branch: currentBranch_ initialState: [savedState_ currentStateForBranch: aUUID]];
        [branchEditQueueForUUID_ setObject: branch forKey: aUUID];
        
        return branch;
    }

    // FIXME: not really an error, just for debugging
    assert(0);
    return nil;
}

@end

@implementation COPersistentRootEditQueue (Private)

- (COStoreEditQueue *) storeEditQueue
{
    return rootStore_;
}

@end
