#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "CORevisionID.h"
#import "COSQLiteStore.h"


@class COBranch;
@class COStore;
@class COEditingContext;

/**
 * goals:
 *  - intended to be the model object backing a document window UI.
 *
 * - support having an object's branches open in their own
 *   windows an editing them simiultaneously
 *
 */
@interface COPersistentRoot : NSObject
{
    COStore *rootStore_; // weak
    
    COPersistentRootState *savedState_;

    /**
     * if the user has called -contextForEditingCurrentBranch,
     * this will hold that context (which is a "singleton"
     * within the context of this COPersistentRootEditQueue
     * instance). 
     */
    COBranch *currentBranch_;
    
    NSMutableDictionary *branchForUUID_;
}

- (COUUID *) UUID;

// metadata & convenience

- (NSDictionary *) metadata;
// commits immediately
- (void) setMetadata: (NSDictionary *)theMetadata;

- (NSString *) name;
// commits immediately
- (void) setName: (NSString *)aName;

// branches


- (NSSet *) branches;

/**
 * @returns array of CORevisionID
 */
- (NSArray *) revisionIDs;

// editing context

/**
 * I made a note that ideal behaviour would be:
 *  - user is working on some feature branch
 *  - user sees an old version on master they want to try working with instead,
 *    so they double-click it
 *  - this creates a new branch at that point and commits it.
 * 
 * ---
 * Commits the new branch immediately
 */
- (COBranch *) createBranchAtRevision: (CORevisionID *)aRevision
                           setCurrent: (BOOL)setCurrent;


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
- (COBranch *) currentBranch;

// commits immediately
- (void) setCurrentBranch: (COBranch *)aBranch;

- (void) removeBranch: (COBranch *)aBranch;

- (COEditingContext *) readonlyContextForViewingRevision: (CORevisionID *)aRevision;

@end
