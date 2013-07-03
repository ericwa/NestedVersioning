#import "COEditCreateBranch.h"
#import "COMacros.h"

@implementation COEditCreateBranch : COEdit

static NSString *kCOBranchUUID = @"COBranchUUID";
static NSString *kCOOldBranchUUID = @"COOldBranchUUID";
static NSString *kCONewVersionToken = @"CONewVersionToken";
static NSString *kCOSetCurrent = @"COSetCurrent";

- (id) initWithOldBranchUUID: (COUUID*)aOldBranchUUID
               newBranchUUID: (COUUID*)aNewBranchUUID
                  setCurrent: (BOOL)setCurrent
                    newToken: (CORevisionID *)newToken
                        UUID: (COUUID*)aUUID
                        date: (NSDate*)aDate
                 displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(aNewBranchUUID);
    NILARG_EXCEPTION_TEST(newToken);
    
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(oldBranch_, aOldBranchUUID);
    ASSIGN(branch_, aNewBranchUUID);
    setCurrent_ = setCurrent;
    ASSIGN(newToken_, newToken);
    return self;
}

- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];

    ASSIGN(oldBranch_, [COUUID UUIDWithString: [plist objectForKey: kCOOldBranchUUID]]);
    ASSIGN(branch_, [COUUID UUIDWithString: [plist objectForKey: kCOBranchUUID]]);
    
    setCurrent_ = [[plist objectForKey: kCOSetCurrent] boolValue];
    ASSIGN(newToken_, [CORevisionID revisionIDWithPlist: [plist objectForKey: kCONewVersionToken]]);
    
    return self;
}
- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: [branch_ stringValue] forKey: kCOBranchUUID];
    [result setObject: [oldBranch_ stringValue] forKey: kCOOldBranchUUID];
    [result setObject: [NSNumber numberWithBool: setCurrent_] forKey: kCOSetCurrent];
    [result setObject: [newToken_ plist] forKey: kCONewVersionToken];
    [result setObject: kCOEditCreateBranch forKey: kCOUndoAction];
    return result;
}

- (COEdit *) inverseForApplicationTo: (COPersistentRootInfo *)aProot
{
    assert(0);
    return nil;
}

- (void) applyToPersistentRoot: (COPersistentRootInfo *)aProot
{
    assert(0);
}

+ (BOOL) isUndoable
{
    return YES;
}

@end
