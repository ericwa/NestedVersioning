#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "CORevisionID.h"

/**
 * An in-memory representation of all of the data about a persistent root.
 *
 * Current branching model:
 *  - branches are linear sequences of commits defined by head and tail (inclusive)
 *  - branches shouldn't overlap each other
 *  - a branch has a current commit, which must be between head and tail (inclusive)
 *
 * as an exception to the above, when a branch is first created it can have a current
 * revision that is anything, and no head or tail.
 *
 */
@interface COPersistentRootPlist : NSObject <NSCopying>
{
    COUUID *uuid_;
   
    // TODO: Store as cache UUID + set of integer ranges for space efficiency
    NSMutableArray *revisionIDs_;
    
    NSMutableDictionary *headRevisionIdForBranch_; // COUUID : CORevisionID
    NSMutableDictionary *tailRevisionIdForBranch_; // COUUID : CORevisionID
    NSMutableDictionary *currentStateForBranch_; // COUUID : CORevisionID
    NSMutableDictionary *metadataForBranch_; // COUUID : NSDictionary
    
    COUUID *currentBranch_;
    
    NSDictionary *metadata_;
}

- (id)      initWithUUID: (COUUID *)aUUID
             revisionIDs: (NSArray *)allRevisions
 headRevisionIdForBranch: (NSDictionary *)headForBranch
 tailRevisionIdForBranch: (NSDictionary *)tailForBranch
   currentStateForBranch: (NSDictionary *)stateForBranch
       metadataForBranch: (NSDictionary *)metadataForBranch
           currentBranch: (COUUID *)currentBranch
                metadata: (NSDictionary *)theMetadata;

- (id) initWithPersistentRootPlist: (COPersistentRootPlist *)aPlist;

- (COUUID *) UUID;
 
- (NSArray *) branchUUIDs;

- (NSArray *) revisionIDs;
- (void) addRevisionID: (CORevisionID *)aRevision;

- (COUUID *) currentBranchUUID;
- (void) setCurrentBranchUUID: (COUUID *)aUUID;

- (CORevisionID *)headRevisionIdForBranch: (COUUID *)aBranch;
- (void)setHeadRevisionId: (CORevisionID *)aRevision
                forBranch: (COUUID *)aUUID;

- (CORevisionID *)tailRevisionIdForBranch: (COUUID *)aBranch;
- (void)setTailRevisionId: (CORevisionID *)aRevision
                forBranch: (COUUID *)aUUID;

- (CORevisionID *)currentStateForBranch: (COUUID *)aBranch;
- (void)setCurrentState: (CORevisionID *)aRevision
              forBranch: (COUUID *)aUUID;

- (NSDictionary *)metadataForBranch: (COUUID *)aBranch;
- (void)setMetadata: (NSDictionary *)aRevision
          forBranch: (COUUID *)aUUID;


- (NSDictionary *) metadata;
- (void) setMetadata: (NSDictionary *)theMetadata;

// Plist import/export

- (id) initWithPlist: (id)aPlist;
- (id) plist;

@end
