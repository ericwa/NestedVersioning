#import "COUndoAction.h"

@interface COUndoActionGroup : COUndoAction
{
    NSArray *actions_;
}

- (id) initWithActions: (NSArray *)actions
                  UUID: (COUUID*)aUUID
                  date: (NSDate*)aDate
           displayName: (NSString*)aName;
@end
