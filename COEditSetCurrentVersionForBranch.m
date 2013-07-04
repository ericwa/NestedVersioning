#import "COEditSetCurrentVersionForBranch.h"
#import <EtoileFoundation/Macros.h>
#import "COSQLiteStore.h"

@implementation COEditSetCurrentVersionForBranch : COEdit

static NSString *kCOBranchUUID = @"COBranchUUID";
static NSString *kCOOldVersionToken = @"COOldVersionToken";
static NSString *kCONewVersionToken = @"CONewVersionToken";

- (id) initWithBranch: (ETUUID *)aBranch
             oldToken: (CORevisionID *)oldToken
             newToken: (CORevisionID *)newToken
                 UUID: (ETUUID*)aUUID
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

    ASSIGN(branch_, [ETUUID UUIDWithString: [plist objectForKey: kCOBranchUUID]]);
    ASSIGN(oldToken_, [CORevisionID revisionIDWithPlist: [plist objectForKey: kCOOldVersionToken]]);
    ASSIGN(newToken_, [CORevisionID revisionIDWithPlist: [plist objectForKey: kCONewVersionToken]]);
    
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

- (COEdit *) inverseForApplicationTo: (COPersistentRootInfo *)aProot
{
    return [[[[self class] alloc] initWithBranch: branch_
                                        oldToken: newToken_
                                        newToken: oldToken_
                                            UUID: uuid_
                                            date: date_
                                     displayName: displayName_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRootInfo *)aProot
{
    [[aProot branchInfoForUUID: branch_] setCurrentRevisionID: newToken_];
}

+ (BOOL) isUndoable
{
    return YES;
}

@end
