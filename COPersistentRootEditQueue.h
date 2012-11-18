#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRootStateToken.h"
#import "COStore.h"

@class COStoreEditQueue;
@class COBranchEditQueue;

/**
 * goals:
 *  - intended to be the model object backing a document window UI.
 *
 * - support having an object's branches open in their own
 *   windows an editing them simiultaneously
 *
 * Restrictions:
 
 
 transaction =
 
   edit:
 
   ( ( create a single new branch on an _already committed_ commit !,
       set current branch to the newly created branch ?,
       set metadata ?) 
     |
 
     ( set current branch! )
 
     |
 
     ( commit to specified branch ! )
  
     |
 
     ( set metadata ! )
   )
 
 create:
 
 ( create a single new branch !,
 set current branch to the newly created one !,
 commit to new branch !,
 set metadata ? )

 
 *
 */
@interface COPersistentRootEditQueue : NSObject
{
    COStoreEditQueue *rootStore_; // weak
    COUUID *uuid_;
    
    BOOL isNew_;
    
    /**
     * nil if isNew_
     */
    id<COPersistentRoot> savedState_;

    /**
     * if the user has called -contextForEditingCurrentBranch,
     * this will hold that context (which is a "singleton"
     * within the context of this COPersistentRootEditQueue
     * instance). 
     */
    COBranchEditQueue *currentBranchEditQueue_;
    
    NSMutableDictionary *branchEditQueueForUUID_;
    
    // <<delta from savedState_
    COUUID *currentBranch_;
    NSDictionary *metadata_;
    COUUID *newBranch_;
    /**
     * if newBranch_ is set this must be set too, to an existing commit (see limitations)
     */
    COPersistentRootStateToken *currentStateForNewBranch_;
    // >>
}

- (COUUID *) UUID;

// metadata & convenience

- (NSDictionary *) metadata;
- (void) setMetadata: (NSDictionary *)theMetadata;

- (NSString *)name;
- (void) setName: (NSString *)aName;

// branches

- (NSArray *) branchUUIDs;

- (COUUID *) currentBranchUUID;
- (void) setCurrentBranchUUID: (COUUID *)aUUID;

/**
 * @returns array of COPersistentRootStateToken
 */
- (NSArray *) allCommits;

// editing context


/**
 * I made a note that ideal behaviour would be:
 *  - user is working on some feature branch
 *  - user sees an old version on master they want to try working with instead,
 *    so they double-click it
 *  - this creates a new branch at that point and commits it.
 * 
 * To implement this, you would call:
 *  -createBranch
 *  -setCurrentState:forBranch:
 *  -setCurrentBranch:
 *  -commitChanges
 *
 * 
 *
 * Initially the newly created branch will be looking at the current state
 * of the persistent root.
 */
- (COBranchEditQueue *) createBranchAndSetCurrent: (BOOL)setCurrent;

/**
 * returns a special proxy context which will
 * change to reflect any changes to the current branch
 *
 * It's going to be a bit of work to handle the case where
 * there is this context open on a particular branch,
 * as well as the explicit one created by -contextForEditingBranchWithUUID
 * because they should stay in sync?
 *
 * On second thought it may not matter.
 */
- (COBranchEditQueue *) contextForEditingCurrentBranch;
- (COBranchEditQueue *) contextForEditingBranchWithUUID: (COUUID *)aUUID;

// undo - these only make sense as standalone ops, not part of a commit, because
//        it wouldn't make sense to make some changes and then undo them before committing!

- (BOOL) canUndo;
- (BOOL) canRedo;

- (NSString *) undoMenuItemTitle;
- (NSString *) redoMenuItemTitle;

- (BOOL) undo;
- (BOOL) redo;

- (NSArray *) undoLog;
- (NSArray *) redoLog;

@end
