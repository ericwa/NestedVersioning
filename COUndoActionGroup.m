#import "COUndoActionGroup.h"
#import "COUndoAction.h"
#import "COMacros.h"

@implementation COUndoActionGroup : COUndoAction

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
        COUndoAction *action = [COUndoAction undoActionWithPlist: actionPlist];
        [(NSMutableArray *)actions_ addObject: action];
    }
    
    return self;
}

- (id)plist
{
    NSMutableArray *actionPlists = [NSMutableArray arrayWithCapacity: [actions_ count]];
    
    for (COUndoAction *action in actions_)
    {
        [actionPlists addObject: [action plist]];
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionary];    
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: actionPlists forKey: kCOActions];
    [result setObject: kCOUndoActionGroup forKey: kCOUndoAction];
    return result;
}

- (COUndoAction *) inverseForApplicationTo: (COPersistentRoot *)aProot
{
    NSMutableArray *actionsReversed = [NSMutableArray arrayWithCapacity: [actions_ count]];
    for (COUndoAction *action in [actions_ reverseObjectEnumerator])
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
    for (COUndoAction *action in actions_)
    {
        [action applyToPersistentRoot: aProot];
    }
}

@end
