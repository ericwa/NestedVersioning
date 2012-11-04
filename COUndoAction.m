#import "COUndoAction.h"
#import "COUndoActionDeleteBranch.h"
#import "COUndoActionCreateBranch.h"
#import "COUndoActionSetCurrentBranch.h"
#import "COUndoActionSetCurrentVersionForBranch.h"
#import "COUndoActionGroup.h"
#import "COMacros.h"

@interface COUndoAction (Private)
- (id) initWithPlist: (id)plist;
@end

@implementation COUndoAction

NSString *kCOUndoActionSetCurrentVersionForBranch = @"COUndoActionSetCurrentVersionForBranch";
NSString *kCOUndoActionDeleteBranch = @"COUndoActionDeleteBranch";
NSString *kCOUndoActionCreateBranch = @"COUndoActionCreateBranch";
NSString *kCOUndoActionSetCurrentBranch = @"COUndoActionSetCurrentBranch";
NSString *kCOUndoAction = @"COUndoAction";

static NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";
static NSString *kCOActionDate = @"COActionDate";
static NSString *kCOActionDisplayName = @"COActionDisplayName";

- (id) initWithUUID: (COUUID*)aUUID
               date: (NSDate*)aDate
        displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(aUUID);
    NILARG_EXCEPTION_TEST(aDate);
    NILARG_EXCEPTION_TEST(aName);
    
    SUPERINIT;
    ASSIGN(uuid_, aUUID);
    ASSIGN(date_, aDate);
    ASSIGN(displayName_, aName);
    return self;
}
- (id) initWithPlist: (id)plist
{
    return [self initWithUUID: [COUUID UUIDWithString: [plist objectForKey: kCOPersistentRootUUID]]
                         date: [plist objectForKey: kCOActionDate]
                  displayName: [plist objectForKey: kCOActionDisplayName]];
}

+ (COUndoAction *) undoActionWithPlist: (id)aPlist
{
    NSString *key = [aPlist objectForKey: kCOUndoAction];
    if ([key isEqual: kCOUndoActionSetCurrentVersionForBranch])
    {
        return [[[COUndoActionSetCurrentVersionForBranch alloc] initWithPlist: aPlist] autorelease];
    }
    else if ([key isEqual: kCOUndoActionDeleteBranch])
    {
        return [[[COUndoActionDeleteBranch alloc] initWithPlist: aPlist] autorelease];
    }
    else if ([key isEqual: kCOUndoActionCreateBranch])
    {
        return [[[COUndoActionCreateBranch alloc] initWithPlist: aPlist] autorelease];
    }
    else if ([key isEqual: kCOUndoActionSetCurrentBranch])
    {
        return [[[COUndoActionSetCurrentBranch alloc] initWithPlist: aPlist] autorelease];
    }
    else if ([key isEqual: kCOUndoActionGroup])
    {
        return [[[COUndoActionGroup alloc] initWithPlist: aPlist] autorelease];
    }
    [NSException raise: NSInvalidArgumentException format: @"invalid plist"];
    return nil;
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject: date_ forKey: kCOActionDate];
    [result setObject: [uuid_ stringValue] forKey: kCOPersistentRootUUID];
    [result setObject: displayName_ forKey: kCOActionDisplayName];
    return result;
}

- (COUUID*) persistentRootUUID
{
    return uuid_;
}

- (NSDate*) date
{
    return date_;
}
- (NSString*) menuTitle
{
    return displayName_;
}
- (COUndoAction *) inverseForApplicationTo: (COPersistentRoot *)aProot
{
    [NSException raise: NSGenericException format: @"unimplemented"];
    return nil;
}

- (void) applyToPersistentRoot: (COPersistentRoot *)aProot
{
    [NSException raise: NSGenericException format: @"unimplemented"];
}

@end
