#import "COUndoAction.h"

@class COBranch;

/**
 * action which can undo the deletion of a branch,
 * or undo the creation of a branch
 */
@interface COUndoActionDeleteBranch : COUndoAction
{
    COBranch *branch_;
    BOOL undoCreate_;
}

- (id) initWithBranch: (COBranch *)aBranch
    isUndoingCreation: (BOOL)unudoCreation
                 UUID: (COUUID*)aUUID
                 date: (NSDate*)aDate
          displayName: (NSString*)aName;

@end
