#import "COPersistentRoot.h"
#import "COStore.h"
#import "COBranch.h"
#import "COMacros.h"
#import "COPersistentRootPlist.h"
#import "COPersistentRootPrivate.h"
#import "COSQLiteStore.h"

@implementation COPersistentRoot

NSString *kCOPersistentRootName = @"COPersistentRootName";

- (id)initWithStoreEditQueue: (COStore *)aRootStore
              persistentRoot: (COPersistentRootPlist *)metadata
{
    SUPERINIT;
    rootStore_ = aRootStore;
    savedState_ = [[COPersistentRootPlist alloc] initWithPersistentRootPlist: metadata];
    branchForUUID_ = [[NSMutableDictionary alloc] init];
    return self;
}

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
    
    if (currentBranch_ != nil)
    {
        [currentBranch_ setBranch: aUUID];
    }
}

- (NSArray *) revisionIDs
{
    return [savedState_ revisionIDs];
}

- (COBranch *) createBranchAtRevision: (CORevisionID *)aRevision
                                    setCurrent: (BOOL)setCurrent
{
    COUUID *aBranch = [[self store] createBranchWithInitialRevision: aRevision
                                                               setCurrent: setCurrent forPersistentRoot: [self UUID]];
    
    // FIXME: Overly coarse
    ASSIGN(savedState_, [[self store] persistentRootWithUUID: [self UUID]]);
    
    // Update current branch edit queue
    if (currentBranch_ != nil)
    {
        [currentBranch_ setBranch: aBranch];
    }
    
    return [self contextForEditingBranchWithUUID: aBranch];
}

- (COBranch *) contextForEditingCurrentBranch
{
    if (currentBranch_ == nil)
    {
        currentBranch_ = [[COBranch alloc] initWithPersistentRoot: self
                                                                             branch: [self currentBranchUUID]
                                                                 trackCurrentBranch: YES];
        
    }
    return currentBranch_;
}

- (COBranch *) contextForEditingBranchWithUUID: (COUUID *)aUUID
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

- (COPersistentRootPlist *) savedState
{
    return savedState_;
}

@end

@implementation COPersistentRoot (Private)

- (COSQLiteStore *) store
{
    return [rootStore_ store];
}

@end
