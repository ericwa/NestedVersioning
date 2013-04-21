#import "COBranch.h"
#import "COMacros.h"
#import "COPersistentRoot.h"
#import "COPersistentRootPrivate.h"
#import "COBranchState.h"
#import "COItemTree.h"
#import "COSQLiteStore.h"
#import "COEditingContext.h"

@implementation COBranch

NSString *kCOBranchName = @"COBranchName";

- (id)initWithPersistentRoot: (COPersistentRoot*)aRoot
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

- (NSDictionary *) metadata
{
    NSDictionary *result = [[[persistentRoot_ savedState] branchPlistForUUID: branch_] metadata];
    if (result == nil)
    {
        return [NSDictionary dictionary];
    }
    return result;
}
- (void) setMetadata: (NSDictionary *)theMetadata
{
    // FIXME: Implement
    assert(0);
}

- (NSString *)name
{
    return [[self metadata] objectForKey: kCOBranchName];
}
- (void) setName: (NSString *)aName
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [self metadata]];
    [dict setObject: aName forKey: kCOBranchName];
    [self setMetadata: dict];
}


- (CORevisionID *)currentRevisionID
{
    return [[[persistentRoot_ savedState] branchPlistForUUID: branch_] currentRevisionID];
}

- (COItemTree *)currentStateObjectTree
{
    return [[persistentRoot_ store] contentsForRevisionID: [self currentRevisionID]];
}

- (CORevisionID *)headRevisionID
{
    return [[[persistentRoot_ savedState] branchPlistForUUID: branch_] headRevisionID];
}

- (CORevisionID *)tailRevisionID
{
    return [[[persistentRoot_ savedState] branchPlistForUUID: branch_] tailRevisionID];
}

- (void) unfaultEditingContext
{
    if (editingContext_ == nil)
    {
        editingContext_ = [[COEditingContext alloc] initWithItemTree: [self currentStateObjectTree]];
    }
}

// commits immediately. discards any uncommitted edits.
// moves the current state pointer of the branch.
- (void) setCurrentRevisionID: (CORevisionID *)aState
{
    [self unfaultEditingContext];
    BOOL ok = [[persistentRoot_ store] setCurrentRevision: aState
                                               forBranch: branch_
                                        ofPersistentRoot: [persistentRoot_ UUID]
                                              updateHead: NO]; // FIXME: YES or NO depending on aState
    assert(ok);
    
    [[[persistentRoot_ savedState] branchPlistForUUID: branch_] setCurrentRevisionID: aState];
    // FIXME: Update head/tail
        
    [editingContext_ setItemTree: [self currentStateObjectTree]];
}

/** @taskunit manipulation */

- (BOOL) commitChangesWithMetadata: (NSDictionary *)metadata
{
    [self unfaultEditingContext];
    
    CORevisionID *revId = [[persistentRoot_ store] writeContents: [editingContext_ itemTree]
                                                    withMetadata: metadata
                                            parentRevisionID: [self currentRevisionID]
                                                   modifiedItems: [[editingContext_ insertedOrModifiedObjectUUIDs] allObjects]];
    [editingContext_ clearChangeTracking];
    
    BOOL ok = [[persistentRoot_ store] setCurrentRevision: revId
                                               forBranch: branch_
                                        ofPersistentRoot: [persistentRoot_ UUID]
                                              updateHead: YES];
    assert(ok);

    [[[persistentRoot_ savedState] branchPlistForUUID: branch_] setCurrentRevisionID:revId];
    // FIXME: Update head/tail
    
    return YES;
}

- (void) discardChanges
{
    if (editingContext_ != nil)
    {
        [editingContext_ setItemTree: [self currentStateObjectTree]];
    }
}

- (BOOL) hasChanges
{
    if (editingContext_ == nil)
    {
        return NO;
    }
    
    return [[editingContext_ insertedObjectUUIDs] count] > 0
        || [[editingContext_ modifiedObjectUUIDs] count] > 0
        || [[editingContext_ deletedObjectUUIDs] count] > 0;
}

- (COEditingContext *)editingContext
{
    [self unfaultEditingContext];
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
