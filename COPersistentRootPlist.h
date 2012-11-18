#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRootStateToken.h"
#import "COStore.h"

/**
 * An in-memory representation of all of the data about a persistent root.
 * Mutable
 *
 * Current branching model:
 *  - each commit is tagged with the SINGLE branch uuid where it was created.
 *  - a branch has a current commit, which doesn't need to be on the branch
 */
@interface COPersistentRootPlist : NSObject <COPersistentRoot, NSCopying>
{
    COUUID *uuid_;
    
    NSMutableDictionary *stateTokensForBranch_; // COUUID : Array of COPersistentRootStateToken
    NSMutableDictionary *currentStateForBranch_; // COUUID : COPersistentRootStateToken

    COUUID *currentBranch_;
    
    NSDictionary *metadata_;
}

- (id)      initWithUUID: (COUUID *)aUUID
    stateTokensForBranch: (NSDictionary *)state
   currentStateForBranch: (NSDictionary *)stateForBranch
           currentBranch: (COUUID *)currentBranch
                metadata: (NSDictionary *)theMetadata;

- (COUUID *) UUID;

- (NSArray *) branchUUIDs;

- (COUUID *) currentBranchUUID;
- (void) setCurrentBranchUUID: (COUUID *)aUUID;

- (NSArray *) stateTokensForBranch: (COUUID *)aBranch;
/**
 * if aBranch does not exist in the receiver,
 * also creates the branch and sets aToken as the current state.
 */
- (void) addStateToken: (COPersistentRootStateToken *)aToken
             forBranch: (COUUID *)aBranch;

- (COPersistentRootStateToken *)currentStateForBranch: (COUUID *)aBranch;
/**
 * if aBranch does not exist in the receiver,
 * creates the branch. 
 */
- (void) setCurrentState: (COPersistentRootStateToken *)aState
               forBranch: (COUUID *)aBranch;

- (NSDictionary *) metadata;
- (void) setMetadata: (NSDictionary *)theMetadata;

// Plist import/export

- (id) initWithPlist: (id)aPlist;
- (id) plist;

@end
