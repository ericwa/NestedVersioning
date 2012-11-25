#import "COEditSetCurrentVersionForBranch.h"
#import "COMacros.h"

@implementation COEditSetCurrentVersionForBranch : COEdit

static NSString *kCOBranchUUID = @"COBranchUUID";
static NSString *kCOOldVersionToken = @"COOldVersionToken";
static NSString *kCONewVersionToken = @"CONewVersionToken";

- (id) initWithBranch: (COUUID *)aBranch
             oldToken: (CORevisionID *)oldToken
             newToken: (CORevisionID *)newToken
                 UUID: (COUUID*)aUUID
                 date: (NSDate*)aDate
          displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(aBranch);
    NILARG_EXCEPTION_TEST(oldToken);
    NILARG_EXCEPTION_TEST(newToken);
    
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(branch_, aBranch);
    ASSIGN(oldToken_, oldToken);
    ASSIGN(newToken_, newToken);
    return self;
}

- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];

    ASSIGN(branch_, [COUUID UUIDWithString: [plist objectForKey: kCOBranchUUID]]);
    ASSIGN(oldToken_, [CORevisionID tokenWithPlist: [plist objectForKey: kCOOldVersionToken]]);
    ASSIGN(newToken_, [CORevisionID tokenWithPlist: [plist objectForKey: kCONewVersionToken]]);
    
    return self;
}
- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: [branch_ stringValue] forKey: kCOBranchUUID];
    [result setObject: [oldToken_ plist] forKey: kCOOldVersionToken];
    [result setObject: [newToken_ plist] forKey: kCONewVersionToken];
    [result setObject: kCOEditSetCurrentVersionForBranch forKey: kCOUndoAction];
    return result;
}

- (COEdit *) inverseForApplicationTo: (COPersistentRootPlist *)aProot
{
    return [[[[self class] alloc] initWithBranch: branch_
                                        oldToken: newToken_
                                        newToken: oldToken_
                                            UUID: uuid_
                                            date: date_
                                     displayName: displayName_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRootPlist *)aProot
{
    [aProot setCurrentState: newToken_ forBranch: branch_];
}

+ (BOOL) isUndoable
{
    return YES;
}

@end
