#import "COEditDeleteBranch.h"
#import "COEditCreateBranch.h"
#import "COMacros.h"
#import "COBranch.h"

@implementation COEditDeleteBranch : COEdit

static NSString *kCOBranchUUID = @"COBranchUUID";

- (id) initWithBranchUUID: (COUUID *)aBranch
                     UUID: (COUUID*)aUUID
                     date: (NSDate*)aDate
              displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(aBranch);
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(branchUUID_, aBranch);
    return self;
}


- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];    
    ASSIGN(branchUUID_, [COUUID UUIDWithString: [plist objectForKey: kCOBranchUUID]]);
    return self;
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: [branchUUID_ stringValue] forKey: kCOBranchUUID];
    [result setObject: kCOEditDeleteBranch forKey: kCOUndoAction];
    return result;
}

- (COEdit *) inverseForApplicationTo: (COPersistentRoot *)aProot
{
    return [[[COEditCreateBranch alloc] initWithBranch: [aProot branchForUUID: branchUUID_]
                                                        UUID: uuid_
                                                        date: date_
                                                 displayName: displayName_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRoot *)aProot
{
    [aProot deleteBranch: branchUUID_];
}

@end
