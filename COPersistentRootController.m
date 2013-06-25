#import "COPersistentRootController.h"
#import "COMacros.h"
#import "COEditingContext.h"
#import "COSQLiteStore.h"
#import "COBranchState.h"

@implementation COPersistentRootController

- (id) initWithStore: (COSQLiteStore *)aStore
  persistentRootUUID: (COUUID *)aUUID
{
    SUPERINIT;
    ASSIGN(store_, aStore);
    ASSIGN(savedState_, [store_ persistentRootWithUUID: aUUID]);
    editingContext_ = [[COEditingContext alloc] init];
    [self discardChanges];
    
    return self;
}

- (COUUID *) UUID
{
    return [savedState_ UUID];
}

- (COUUID *) editingBranchUUID
{
    return [savedState_ currentBranchUUID];
}

/**
 * Commits on change
 */
- (void) setEditingBranchUUID: (COUUID*)aBranch
{
    assert([store_ setCurrentBranch: aBranch
                  forPersistentRoot: [savedState_ UUID]]);
    
    ASSIGN(savedState_, [store_ persistentRootWithUUID: [self UUID]]);
}

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) resetToRevisionID: (CORevisionID *)aState
{
    BOOL ok = [store_ setCurrentRevision: aState
                            headRevision: nil
                            tailRevision: nil
                               forBranch: [savedState_ currentBranchUUID]
                        ofPersistentRoot: [savedState_ UUID]];
    assert(ok);
    
    
    ASSIGN(savedState_, [store_ persistentRootWithUUID: [self UUID]]);
    
    [self discardChanges];
}

- (void) resetToRevisionIDNoCommit: (CORevisionID *)aState
{
    CORevisionID *revid = [[savedState_ currentBranchState] currentRevisionID];
    COItemTree *tree = [store_ contentsForRevisionID: revid];
    [editingContext_ setItemTree: tree];
}

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata
{
    CORevisionID *revId = [store_ writeContents: editingContext_
                                   withMetadata: metadata
                               parentRevisionID: [[savedState_ currentBranchState] currentRevisionID]
                                  modifiedItems: [[editingContext_ insertedOrModifiedObjectUUIDs] allObjects]];
    [editingContext_ clearChangeTracking];
    
    BOOL ok = [store_ setCurrentRevision: revId
                            headRevision: revId
                            tailRevision: nil
                               forBranch: [savedState_ currentBranchUUID]
                        ofPersistentRoot: [savedState_ UUID]];
    assert(ok);
    
    ASSIGN(savedState_, [store_ persistentRootWithUUID: [self UUID]]);
    
    return YES;

}
- (void) discardChanges
{
    CORevisionID *revid = [[savedState_ currentBranchState] currentRevisionID];
    [self resetToRevisionIDNoCommit: revid];
}
- (BOOL) hasChanges
{
    return [[editingContext_ insertedObjectUUIDs] count] > 0
        || [[editingContext_ modifiedObjectUUIDs] count] > 0;
}

- (COEditingContext *) editingContext
{
    return editingContext_;
}

@end
