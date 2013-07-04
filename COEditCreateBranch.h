#import "COEdit.h"
#import "CORevisionID.h"

/**
 * undo setting from old -> new (to apply, replace new by old)
 */
@interface COEditCreateBranch : COEdit
{
    ETUUID *oldBranch_;
    ETUUID *branch_;
    CORevisionID *newToken_;
    BOOL setCurrent_;
}

- (id) initWithOldBranchUUID: (ETUUID*)aOldBranchUUID
               newBranchUUID: (ETUUID*)aNewBranchUUID
                  setCurrent: (BOOL)setCurrent
                    newToken: (CORevisionID *)newToken
                        UUID: (ETUUID*)aUUID
                        date: (NSDate*)aDate
                 displayName: (NSString*)aName;

@end
