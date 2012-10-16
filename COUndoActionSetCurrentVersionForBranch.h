#import "COUndoAction.h"
#import "COPersistentRootStateToken.h"

/**
 * undo setting from old -> new (to apply, replace new by old)
 */
@interface COUndoActionSetCurrentVersionForBranch : COUndoAction
{
    COUUID *branch_;
    COPersistentRootStateToken *oldToken_;
    COPersistentRootStateToken *newToken_;
}

- (id) initWithBranch: (COUUID *)aBranch
             oldToken: (COPersistentRootStateToken *)oldToken
             newToken: (COPersistentRootStateToken *)newToken
                 UUID: (COUUID*)aUUID
                 date: (NSDate*)aDate
          displayName: (NSString*)aName;

@end
