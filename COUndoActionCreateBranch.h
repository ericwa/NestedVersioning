#import "COUndoAction.h"

@class COBranch;

/**
 * action which can undo the creation of a branch
 */
@interface COUndoActionCreateBranch : COUndoAction
{
    COUUID *branchUUID_;
}

- (id) initWithBranchUUID: (COUUID *)aBranch
                     UUID: (COUUID*)aUUID
                     date: (NSDate*)aDate
              displayName: (NSString*)aName;

@end
