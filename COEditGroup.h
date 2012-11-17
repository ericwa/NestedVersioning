#import "COEdit.h"

@interface COEditGroup : COEdit
{
    NSArray *actions_;
}

- (id) initWithActions: (NSArray *)actions
                  UUID: (COUUID*)aUUID
                  date: (NSDate*)aDate
           displayName: (NSString*)aName;
@end
