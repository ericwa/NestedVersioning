#import "COEditDeleteBranch.h"
#import "COEditCreateBranch.h"
#import "COMacros.h"


@implementation COEditDeleteBranch : COEdit

static NSString *kCOBranch = @"COBranch";

- (id) initWithBranchPlist: (COBranchInfo *)aBranch
                      UUID: (ETUUID*)aUUID
                      date: (NSDate*)aDate
               displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(aBranch);
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(branch_, aBranch);
    return self;
}


- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];    
    branch_ = [[COBranchInfo alloc] initWithPlist: [plist objectForKey: kCOBranch]];
    return self;
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: [branch_ plist] forKey: kCOBranch];
    [result setObject: kCOEditDeleteBranch forKey: kCOUndoAction];
    return result;
}

@end
