#import "COEditCreateBranch.h"
#import "COMacros.h"

@implementation COEditCreateBranch : COEdit

- (id) initWithBranchUUID: (COUUID *)newUUID
             currentState: (CORevisionID *)state
                     UUID: (COUUID*)aUUID
                     date: (NSDate*)aDate
              displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(newUUID);
    NILARG_EXCEPTION_TEST(state);
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(newUUID_, newUUID);
    ASSIGN(currentState_, state);
    return self;
}


- (id) initWithPlist: (id)plist
{
    [NSException raise: NSGenericException format: @"not undoable"];
    return nil;
}

- (id)plist
{
    [NSException raise: NSGenericException format: @"not undoable"];
    return nil;
}

- (COEdit *) inverseForApplicationTo: (COPersistentRootPlist *)aProot
{
    [NSException raise: NSGenericException format: @"not undoable"];
    return nil;
}

- (void) applyToPersistentRoot: (COPersistentRootPlist *)aProot
{
    [aProot setCurrentState: currentState_ forBranch: newUUID_];
}

+ (BOOL) isUndoable
{
    return NO;
}

@end
