#import <Foundation/Foundation.h>

#import "COUUID.h"

@class COPersistentRootStateToken;

@interface COBranch : NSObject <NSMutableCopying>
{
    COUUID *uuid_;
    NSString *name_;
    
    /**
     * We can store this as an NSIndexSet type data structure for very low overhead.
     * So COBranch can have O(1) size if all commits are contiguous in the DB.
     * or O(n) where n is number of contiguous ranges of commits.
     */
    NSMutableArray *stateTokens;
    COPersistentRootStateToken *currentState;
    
    id metadata;
}

- (id) initWithUUID: (COUUID *)aUUID
               name: (NSString *)name
       initialState: (COPersistentRootStateToken *)state
           metadata: (id)aMetadata;


- (COUUID *)UUID;
- (void) setUUID: (COUUID *)aUUID;
- (NSString *)name;
- (COPersistentRootStateToken *)currentState;
/**
 * @return array of COPersistentRootStateToken
 */
- (NSArray *)allCommits;

- (id) metadata;

- (id) _plist;
+ (COBranch *) _branchWithPlist: (id)plist;
- (void) _addCommit: (COPersistentRootStateToken *)aCommit;
- (void) _setCurrentState: (COPersistentRootStateToken *)aCommit;

- (id)mutableCopyWithZone:(NSZone *)zone;
- (COBranch *) branchWithCurrentState;

@end
