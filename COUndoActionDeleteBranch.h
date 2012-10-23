#import "COUndoAction.h"

@class COBranch;

/**
 * action which can undo the deletion of a branch
 */
@interface COUndoActionDeleteBranch : COUndoAction
{
    COBranch *branch_;
}

- (id) initWithBranch: (COBranch *)aBranch
                 UUID: (COUUID*)aUUID
                 date: (NSDate*)aDate
          displayName: (NSString*)aName;

@end
