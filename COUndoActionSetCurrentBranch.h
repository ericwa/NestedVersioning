#import "COUndoAction.h"

@interface COUndoActionSetCurrentBranch : COUndoAction
{
    COUUID *oldBranch_;
    COUUID *newBranch_;

}

- (id) initWithOldBranchUUID: (COUUID*)aOldBranchUUID
               newBranchUUID: (COUUID*)aNewBranchUUID
                        UUID: (COUUID*)aUUID
                        date: (NSDate*)aDate
                 displayName: (NSString*)aName;
@end
