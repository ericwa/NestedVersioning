#import "COEditGroup.h"
#import "COEdit.h"
#import "COMacros.h"

@implementation COEditGroup : COEdit

static NSString *kCOActions = @"COActions";

- (id) initWithActions: (NSArray *)actions
                  UUID: (COUUID*)aUUID
                  date: (NSDate*)aDate
           displayName: (NSString*)aName;
{
    NILARG_EXCEPTION_TEST(actions);
    
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(actions_, actions);
    return self;
}

- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];
    
    actions_ = [[NSMutableArray alloc] initWithCapacity: [plist count]];
    
    for (id actionPlist in plist)
    {
        COEdit *action = [COEdit undoActionWithPlist: actionPlist];
        [(NSMutableArray *)actions_ addObject: action];
    }
    
    return self;
}

- (id)plist
{
    NSMutableArray *actionPlists = [NSMutableArray arrayWithCapacity: [actions_ count]];
    
    for (COEdit *action in actions_)
    {
        [actionPlists addObject: [action plist]];
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionary];    
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: actionPlists forKey: kCOActions];
    [result setObject: kCOEditGroup forKey: kCOUndoAction];
    return result;
}

- (COEdit *) inverseForApplicationTo: (COPersistentRoot *)aProot
{
    NSMutableArray *actionsReversed = [NSMutableArray arrayWithCapacity: [actions_ count]];
    for (COEdit *action in [actions_ reverseObjectEnumerator])
    {
        [actionsReversed addObject: [action inverseForApplicationTo: aProot]];
    }
    
    return [[[[self class] alloc] initWithActions:actionsReversed
                                             UUID: uuid_
                                             date: date_
                                      displayName: displayName_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRoot *)aProot
{
    for (COEdit *action in actions_)
    {
        [action applyToPersistentRoot: aProot];
    }
}

@end
