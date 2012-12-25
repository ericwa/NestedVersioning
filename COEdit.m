#import "COEdit.h"
#import "COEditSetCurrentBranch.h"
#import "COEditSetCurrentVersionForBranch.h"
#import "COEditSetMetadata.h"
#import "COMacros.h"

@interface COEdit (Private)
- (id) initWithPlist: (id)plist;
@end

@implementation COEdit

NSString *kCOEditSetCurrentVersionForBranch = @"COEditSetCurrentVersionForBranch";
NSString *kCOEditSetCurrentBranch = @"COEditSetCurrentBranch";
NSString *kCOEditSetBranchMetadata = @"COEditSetBranchMetadata";
NSString *kCOEditGroup = @"COEditGroup";
NSString *kCOEditSetMetadata = @"COEditSetMetadata";

NSString *kCOUndoAction = @"COEdit";

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

+ (COEdit *) undoActionWithPlist: (id)aPlist
{
    NSString *key = [aPlist objectForKey: kCOUndoAction];
    if ([key isEqual: kCOEditSetCurrentVersionForBranch])
    {
        return [[[COEditSetCurrentVersionForBranch alloc] initWithPlist: aPlist] autorelease];
    }
    else if ([key isEqual: kCOEditSetCurrentBranch])
    {
        return [[[COEditSetCurrentBranch alloc] initWithPlist: aPlist] autorelease];
    }
    else if ([key isEqual: kCOEditSetMetadata])
    {
        return [[[COEditSetMetadata alloc] initWithPlist: aPlist] autorelease];
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
- (COEdit *) inverseForApplicationTo: (COPersistentRootPlist *)aProot
{
    [NSException raise: NSGenericException format: @"unimplemented"];
    return nil;
}

- (void) applyToPersistentRoot: (COPersistentRootPlist *)aProot
{
    [NSException raise: NSGenericException format: @"unimplemented"];
}

+ (BOOL) isUndoable
{
    [NSException raise: NSGenericException format: @"unimplemented"];
    return NO;
}

@end
