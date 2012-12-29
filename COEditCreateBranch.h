#import "COEdit.h"
#import "CORevisionID.h"

/**
 * undo setting from old -> new (to apply, replace new by old)
 */
@interface COEditCreateBranch : COEdit
{
    COUUID *oldBranch_;
    COUUID *branch_;
    CORevisionID *newToken_;
    BOOL setCurrent_;
}

- (id) initWithOldBranchUUID: (COUUID*)aOldBranchUUID
               newBranchUUID: (COUUID*)aNewBranchUUID
                  setCurrent: (BOOL)setCurrent
                    newToken: (CORevisionID *)newToken
                        UUID: (COUUID*)aUUID
                        date: (NSDate*)aDate
                 displayName: (NSString*)aName;

@end
