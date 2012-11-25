#import "COBranchEditQueue.h"
#import "COMacros.h"
#import "COSubtree.h"
#import "COPersistentRootEditQueue.h"
#import "COEditQueuePrivate.h"
#import "COObjectTree.h"
#import "COSQLiteStore.h"

@implementation COBranchEditQueue

- (id)initWithPersistentRoot: (COPersistentRootEditQueue*)aRoot
                      branch: (COUUID*)aBranch
          trackCurrentBranch: (BOOL)track
{
    SUPERINIT;
    persistentRoot_ = aRoot;
    ASSIGN(branch_, aBranch);
    isTrackingCurrentBranch_ = track;
    return self;
}

- (void)dealloc
{
    [branch_ release];
    [backupTree_ release];
    [tree_ release];
    [modifiedObjects_ release];
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

- (CORevisionID *)currentState
{
    return [[persistentRoot_ savedState] currentStateForBranch: branch_];
}

- (CORevisionID *)head
{
    return [[persistentRoot_ savedState] headRevisionIdForBranch: branch_];
}

- (CORevisionID *)tail
{
    return [[persistentRoot_ savedState] tailRevisionIdForBranch: branch_];
}

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) setCurrentState: (CORevisionID *)aState
{
    BOOL ok = [[persistentRoot_ store] setCurrentVersion: aState
                                               forBranch: branch_
                                        ofPersistentRoot: [persistentRoot_ UUID]];
    
    [[persistentRoot_ savedState] setCurrentState: aState forBranch: branch_];
    // FIXME: Update head/tail
}

/** @taskunit manipulation */

static COObjectTree *itemTreeForSubtree(COSubtree *aSubtree)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (COItem *item in [aSubtree allContainedStoreItems])
    {
        [dict setObject: item forKey: [item UUID]];
    }
    return [[[COObjectTree alloc] initWithItemForUUID: dict root: [aSubtree UUID]] autorelease];
}

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata
{
    CORevisionID *revId = [[persistentRoot_ store] writeItemTree: itemTreeForSubtree(tree_)
                                                    withMetadata: metadata
                                            withParentRevisionID: [self currentState]
                                                   modifiedItems: [[tree_ allUUIDs] allObjects]];

    BOOL ok = [[persistentRoot_ store] setCurrentVersion: revId
                                               forBranch: branch_
                                        ofPersistentRoot: [persistentRoot_ UUID]];
    assert(ok);

    [[persistentRoot_ savedState] setCurrentState:revId forBranch: branch_];
    // FIXME: Update head/tail
    
    return YES;
}

- (void) discardChanges
{
    [tree_ release];
    tree_ = [backupTree_ copy];
}

// FIXME: Rewrite using editing context
- (COSubtree *)persistentRootTree
{
    return tree_;
}
- (void) setPersistentRootTree: (COSubtree *)aSubtree
{
    ASSIGN(tree_, aSubtree);
}

/**
 * the branch of the special "current branch" edit queue
 * can change.
 */
- (void) setBranch: (COUUID *)aBranch
{
    assert(isTrackingCurrentBranch_);
    ASSIGN(branch_, aBranch);
    [self discardChanges];
}

@end
