#import "COBranch.h"
#import "COMacros.h"
#import "COPersistentRoot.h"
#import "COEditQueuePrivate.h"
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
    editingContext_ = [[COEditingContext alloc] initWithObjectTree: [self currentStateObjectTree]];
    
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

- (CORevisionID *)currentState
{
    return [[persistentRoot_ savedState] currentStateForBranch: branch_];
}

- (COItemTree *)currentStateObjectTree
{
    return [[persistentRoot_ store] objectTreeForRevision: [self currentState]];
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
    assert(ok);
    
    [[persistentRoot_ savedState] setCurrentState: aState forBranch: branch_];
    // FIXME: Update head/tail
    
    [editingContext_ setObjectTree: [self currentStateObjectTree]];
}

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata
{
    CORevisionID *revId = [[persistentRoot_ store] writeItemTree: [editingContext_ objectTree]
                                                    withMetadata: metadata
                                            withParentRevisionID: [self currentState]
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
    [editingContext_ setObjectTree: [self currentStateObjectTree]];
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
