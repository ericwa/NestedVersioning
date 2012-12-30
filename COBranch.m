#import "COBranch.h"
#import "COMacros.h"
#import "COPersistentRoot.h"
#import "COPersistentRootPrivate.h"
#import "COItemTree.h"
#import "COSQLiteStore.h"
#import "COEditingContext.h"

@implementation COBranch

- (id)initWithPersistentRoot: (COPersistentRoot*)aRoot
                      branch: (COUUID*)aBranch
          trackCurrentBranch: (BOOL)track
{
    SUPERINIT;
    persistentRoot_ = aRoot;
    ASSIGN(branch_, aBranch);
    isTrackingCurrentBranch_ = track;
    editingContext_ = [[COEditingContext alloc] initWithItemTree: [self currentStateObjectTree]];
    
    return self;
}

- (void)dealloc
{
    [branch_ release];
    [editingContext_ release];
    [super dealloc];
}

- (COPersistentRoot *) persistentRoot
{
    return persistentRoot_;
}
- (COUUID *) UUID
{
    return branch_;
}

- (CORevisionID *)currentRevisionID
{
    return [[persistentRoot_ savedState] currentStateForBranch: branch_];
}

- (COItemTree *)currentStateObjectTree
{
    return [[persistentRoot_ store] objectTreeForRevision: [self currentRevisionID]];
}

- (CORevisionID *)headRevisionID
{
    return [[persistentRoot_ savedState] headRevisionIdForBranch: branch_];
}

- (CORevisionID *)tailRevisionID
{
    return [[persistentRoot_ savedState] tailRevisionIdForBranch: branch_];
}

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) setCurrentRevisionID: (CORevisionID *)aState
{
    BOOL ok = [[persistentRoot_ store] setCurrentVersion: aState
                                               forBranch: branch_
                                        ofPersistentRoot: [persistentRoot_ UUID]];
    assert(ok);
    
    [[persistentRoot_ savedState] setCurrentState: aState forBranch: branch_];
    // FIXME: Update head/tail
    
    [editingContext_ setItemTree: [self currentStateObjectTree]];
}

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata
{
    CORevisionID *revId = [[persistentRoot_ store] writeItemTree: [editingContext_ itemTree]
                                                    withMetadata: metadata
                                            withParentRevisionID: [self currentRevisionID]
                                                   modifiedItems: [[editingContext_ insertedOrModifiedObjectUUIDs] allObjects]];
    [editingContext_ clearChangeTracking];
    
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
    [editingContext_ setItemTree: [self currentStateObjectTree]];
}

- (BOOL) hasChanges
{
    return [[editingContext_ insertedObjectUUIDs] count] > 0
        || [[editingContext_ modifiedObjectUUIDs] count] > 0
        || [[editingContext_ deletedObjectUUIDs] count] > 0;
}

- (COEditingContext *)editingContext
{
    return editingContext_;
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
