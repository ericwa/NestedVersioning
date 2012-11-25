#import "COEdit.h"
#import "CORevisionID.h"

/**
 * undo setting from old -> new (to apply, replace new by old)
 */
@interface COEditSetCurrentVersionForBranch : COEdit
{
    COUUID *branch_;
    CORevisionID *oldToken_;
    CORevisionID *newToken_;
}

- (id) initWithBranch: (COUUID *)aBranch
             oldToken: (CORevisionID *)oldToken
             newToken: (CORevisionID *)newToken
                 UUID: (COUUID*)aUUID
                 date: (NSDate*)aDate
          displayName: (NSString*)aName;

@end
