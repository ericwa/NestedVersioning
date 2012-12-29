#import <Foundation/Foundation.h>

@class COUUID;
@class CORevisionID;
@class COBranchState;

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
@interface COPersistentRootState : NSObject <NSCopying>
{
    COUUID *uuid_;
   
    // TODO: Store as cache UUID + set of integer ranges for space efficiency
    NSMutableArray *revisionIDs_;
    
    NSMutableDictionary *branchForUUID_; // COUUID : COBranchPlist
    
    COUUID *currentBranch_;
    
    NSDictionary *metadata_;
}

- (id) initWithUUID: (COUUID *)aUUID
        revisionIDs: (NSArray *)allRevisions
      branchForUUID: (NSDictionary *)branchForUUID
  currentBranchUUID: (COUUID *)currentBranch
           metadata: (NSDictionary *)theMetadata;

- (id) initWithPersistentRootPlist: (COPersistentRootState *)aPlist;
 
- (NSSet *) branchUUIDs;

- (NSArray *) revisionIDs;
- (void) addRevisionID: (CORevisionID *)aRevision;

- (COBranchState *)branchPlistForUUID: (COUUID *)aUUID;
- (void)setBranchPlist: (COBranchState *)aBranch
               forUUID: (COUUID *)aUUID;
- (void)removeBranchForUUID: (COUUID *)aUUID;

@property (readonly, nonatomic) COUUID *UUID;
@property (nonatomic, copy, readwrite) NSDictionary *metadata;
@property (nonatomic, copy, readwrite) COUUID *currentBranchUUID;

// Plist import/export

- (id) initWithPlist: (id)aPlist;
- (id) plist;

@end
