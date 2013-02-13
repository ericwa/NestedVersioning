#import "COEdit.h"
#import "COEditCreateBranch.h"
#import "COEditDeleteBranch.h"
#import "COEditSetCurrentBranch.h"
#import "COEditSetCurrentVersionForBranch.h"
#import "COEditSetMetadata.h"
#import "COEditSetBranchMetadata.h"
#import "COMacros.h"

@interface COEdit (Private)
- (id) initWithPlist: (id)plist;
@end

@implementation COEdit

NSString *kCOEditCreateBranch = @"COEditCreateBranch";
NSString *kCOEditDeleteBranch = @"COEditDeleteBranch";
NSString *kCOEditSetCurrentVersionForBranch = @"COEditSetCurrentVersionForBranch";
NSString *kCOEditSetCurrentBranch = @"COEditSetCurrentBranch";
NSString *kCOEditSetBranchMetadata = @"COEditSetBranchMetadata";
NSString *kCOEditSetMetadata = @"COEditSetMetadata";

NSString *kCOUndoAction = @"COEdit";

static NSString *kCOPersistentRootUUID = @"COPersistentRootUUID";
static NSString *kCOActionDate = @"COActionDate";
static NSString *kCOActionDisplayName = @"COActionDisplayName";
static NSString *kCOOperationMetadata = @"COOperationMetadata";

- (id) initWithUUID: (COUUID*)aUUID
               date: (NSDate*)aDate
        displayName: (NSString*)aName
  operationMetadata: (NSDictionary *)opMetadata
{
    NILARG_EXCEPTION_TEST(aUUID);
    NILARG_EXCEPTION_TEST(aDate);
    NILARG_EXCEPTION_TEST(aName);
    
    SUPERINIT;
    ASSIGN(uuid_, aUUID);
    ASSIGN(date_, aDate);
    ASSIGN(displayName_, aName);
    ASSIGN(operationMetadata_, opMetadata);
    return self;
}
- (id) initWithPlist: (id)plist
{
    NSParameterAssert([self class] != [COEdit class]);
        
    return [self initWithUUID: [COUUID UUIDWithString: [plist objectForKey: kCOPersistentRootUUID]]
                         date: [[[[NSDateFormatter alloc] init] autorelease] dateFromString: [plist objectForKey: kCOActionDate]]
                  displayName: [plist objectForKey: kCOActionDisplayName]
            operationMetadata: [plist objectForKey: kCOOperationMetadata]];
}

+ (COEdit *) editWithPlist: (id)aPlist
{
    NSString *key = [aPlist objectForKey: kCOUndoAction];
    
    Class cls = [D([COEditCreateBranch class], kCOEditCreateBranch,
                   [COEditDeleteBranch class], kCOEditDeleteBranch,
                   [COEditSetCurrentVersionForBranch class], kCOEditSetCurrentVersionForBranch,
                   [COEditSetCurrentBranch class], kCOEditSetCurrentBranch,
                   [COEditSetMetadata class], kCOEditSetMetadata,
                   [COEditSetBranchMetadata class], kCOEditSetBranchMetadata) objectForKey: key];
    

    if (cls != Nil)
    {
        return [[[cls alloc] initWithPlist: aPlist] autorelease];
    }
    else
    {
        [NSException raise: NSInvalidArgumentException format: @"invalid plist"];
        return nil;
    }
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject: [[[[NSDateFormatter alloc] init] autorelease] stringFromDate: date_] forKey: kCOActionDate];
    [result setObject: [uuid_ stringValue] forKey: kCOPersistentRootUUID];
    [result setObject: displayName_ forKey: kCOActionDisplayName];
    if (operationMetadata_ != nil)
    {
        [result setObject: operationMetadata_ forKey: kCOOperationMetadata];
    }
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
- (NSDictionary *) operationMetadata
{
    return operationMetadata_;
}
- (COEdit *) inverseForApplicationTo: (COPersistentRootState *)aProot
{
    [NSException raise: NSGenericException format: @"unimplemented"];
    return nil;
}

- (void) applyToPersistentRoot: (COPersistentRootState *)aProot
{
    [NSException raise: NSGenericException format: @"unimplemented"];
}

+ (BOOL) isUndoable
{
    [NSException raise: NSGenericException format: @"unimplemented"];
    return NO;
}

- (NSString *) description
{
    return [[self plist] description];
}

@end
