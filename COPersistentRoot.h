#import <Foundation/Foundation.h>

@class COUUID;
@class COBranch;

/**
 * An in-memory representation of all of the data about a persistent root.
 * Mutable
 */
@interface COPersistentRoot : NSObject
{
    COUUID *uuid;
    
    NSMutableDictionary *branches;
    COUUID *currentBranch;
    
    NSDictionary *metadata;
}

- (id) initWithUUID: (COUUID *)aUUID
           branches: (NSArray *)theBranches
      currentBranch: (COUUID *)aBranch
           metadata: (NSDictionary *)theMetadata;

- (COUUID *) UUID;

/**
 * @return set of COBranch
 */
- (NSArray *) branches;

- (COBranch *) currentBranch;
- (COBranch *) branchForUUID: (COUUID *)aUUID;

- (NSDictionary *) metadata;

// @taskunit private

- (id) initWithPlist: (id)aPlist;
- (id) plist;

/**
 * Defines copy semantics for proots
 */
- (COPersistentRoot *) persistentRootWithNewName;

- (void) deleteBranch: (COUUID *)aUUID;
- (void) addBranch: (COBranch *)aBranch;
- (void) setCurrentBranch: (COUUID *)aUUID;
- (COBranch *) _makeCopyOfBranch: (COUUID *)aUUID;

/**
 * Only copyies the in-memory object, doesn't commit anything to store!
 */
- (COPersistentRoot *) persistentRootCopyingBranch: (COUUID *)aUUID;

@end
