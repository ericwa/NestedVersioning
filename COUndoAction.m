#import "COUndoAction.h"
#import "COUndoActionDeleteBranch.h"
#import "COUndoActionSetCurrentBranch.h"
#import "COUndoActionSetCurrentVersionForBranch.h"
#import "COMacros.h"

@interface COUndoAction (Private)
- (id) initWithPlist: (id)plist;
@end

@implementation COUndoAction

NSString *kCOUndoActionSetCurrentVersionForBranch = @"COUndoActionSetCurrentVersionForBranch";
NSString *kCOUndoActionDeleteBranch = @"COUndoActionDeleteBranch";
NSString *kCOUndoActionSetCurrentBranch = @"COUndoActionSetCurrentBranch";
NSString *kCOUndoAction = @"COUndoAction";

static NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";
static NSString *kCOActionDate = @"COActionDate";
static NSString *kCOActionDisplayName = @"COActionDisplayName";

- (id) initWithUUID: (COUUID*)aUUID
               date: (NSDate*)aDate
        displayName: (NSString*)aName
{
    SUPERINIT;
    ASSIGN(uuid_, aUUID);
    if (![uuid_ isKindOfClass: [COUUID class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected COUUID"];
    }
    ASSIGN(date_, aDate);
    if (![date_ isKindOfClass: [NSDate class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected date"];
    }
    ASSIGN(displayName_, aName);
    if (![displayName_ isKindOfClass: [NSString class]])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected string"];
    }
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
    else if ([key isEqual: kCOUndoActionSetCurrentBranch])
    {
        return [[[COUndoActionSetCurrentBranch alloc] initWithPlist: aPlist] autorelease];
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
- (COUndoAction *) inverse
{
    [NSException raise: NSGenericException format: @"unimplemented"];
    return nil;
}

- (void) applyToPersistentRoot: (COPersistentRoot *)aProot
{
    [NSException raise: NSGenericException format: @"unimplemented"];
}

@end
