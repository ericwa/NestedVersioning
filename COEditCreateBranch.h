#import "COEdit.h"

@class COBranch;

/**
 * action which can undo the deletion of a branch
 */
@interface COEditCreateBranch : COEdit
{
    COUUID *newUUID_;
    COPersistentRootStateToken *currentState_;
}

- (id) initWithBranchUUID: (COUUID *)newUUID
             currentState: (COPersistentRootStateToken *)state
                     UUID: (COUUID*)aUUID
                     date: (NSDate*)aDate
              displayName: (NSString*)aName;

@end
