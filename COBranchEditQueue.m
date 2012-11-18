#import "COBranchEditQueue.h"
#import "COMacros.h"
#import "COSubtree.h"
#import "COPersistentRootEditQueue.h"
#import "COEditQueuePrivate.h"

@implementation COBranchEditQueue

/**
 * if aState is nil, we are uncommitted 
 */
- (id)initWithRoot: (COPersistentRootEditQueue*)aRoot branch: (COUUID*)aBranch initialState: (COPersistentRootStateToken *)aState
{
    assert(aBranch != nil);
    assert(aRoot  != nil);
    
    SUPERINIT;
    persistentRoot_ = aRoot; // weak
    ASSIGN(branch_, aBranch);

    if (aState != nil)
    {
        ASSIGN(tree_, [[[[persistentRoot_ storeEditQueue] store] fullStateForToken: aState] tree]);
        backupTree_ = [tree_ copy];
    }
    else
    {
        tree_ = [[COSubtree alloc] init];
    }
    
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (COPersistentRootEditQueue *) persistentRoot
{
    return persistentRoot_;
}

- (COUUID *) UUID
{
    return branch_;
}

- (void) setBranch: (COUUID *)aBranch
{
    ASSIGN(branch_, aBranch);
    
    // TODO: reload ourself.
}

/** @taskunit manipulation */


- (BOOL) commitChanges;
{
    return [persistentRoot_ commitChanges];
}

- (void) discardChanges
{
    // TODO
}

- (COSubtree *)persistentRootTree
{
    return tree_;
}

- (void) setPersistentRootTree: (COSubtree *)aSubtree
{
    ASSIGN(tree_, aSubtree);
}

- (COPersistentRootState *) fullState
{
    return [COPersistentRootState stateWithTree: tree_];
}

@end
