#import "COEdit.h"

@class COBranch;

/**
 * action which can undo the deletion of a branch
 */
@interface COEditCreateBranch : COEdit
{
    COUUID *newUUID_;
    CORevisionID *currentState_;
}

- (id) initWithBranchUUID: (COUUID *)newUUID
             currentState: (CORevisionID *)state
                     UUID: (COUUID*)aUUID
                     date: (NSDate*)aDate
              displayName: (NSString*)aName;

@end
