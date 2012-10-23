#import "COUndoActionDeleteBranch.h"
#import "COUndoActionCreateBranch.h"
#import "COMacros.h"
#import "COBranch.h"

@implementation COUndoActionDeleteBranch : COUndoAction

static NSString *kCOBranchBackup = @"COBranchBackup";

- (id) initWithBranch: (COBranch *)aBranch
                 UUID: (COUUID*)aUUID
                 date: (NSDate*)aDate
          displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(aBranch);
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(branch_, [[aBranch mutableCopy] autorelease]);
    return self;
}


- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];
    ASSIGN(branch_, [COBranch _branchWithPlist: [plist objectForKey: kCOBranchBackup]]);
    return self;
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: [branch_ _plist] forKey: kCOBranchBackup];
    [result setObject: kCOUndoActionDeleteBranch forKey: kCOUndoAction];
    return result;
}

- (COUndoAction *) inverseForApplicationTo: (COPersistentRoot *)aProot
{
    return [[[COUndoActionCreateBranch alloc] initWithBranchUUID: [branch_ UUID]
                                                            UUID: uuid_
                                                            date: date_
                                                     displayName: displayName_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRoot *)aProot
{
    [aProot addBranch: branch_];
}

@end
