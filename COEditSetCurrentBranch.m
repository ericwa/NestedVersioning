#import "COEditSetCurrentBranch.h"
#import "COMacros.h"

@implementation COEditSetCurrentBranch : COEdit

static NSString *kCOOldBranchUUID = @"COOldBranchUUID";
static NSString *kCONewBranchUUID = @"CONewBranchUUID";

- (id) initWithOldBranchUUID: (COUUID*)aOldBranchUUID
               newBranchUUID: (COUUID*)aNewBranchUUID
                        UUID: (COUUID*)aUUID
                        date: (NSDate*)aDate
                 displayName: (NSString*)aName
{
    NILARG_EXCEPTION_TEST(aOldBranchUUID);
    NILARG_EXCEPTION_TEST(aNewBranchUUID);
    
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(oldBranch_, aOldBranchUUID);
    ASSIGN(newBranch_, aNewBranchUUID);
    return self;
}


- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];
    
    ASSIGN(oldBranch_, [COUUID UUIDWithString: [plist objectForKey: kCOOldBranchUUID]]);
    ASSIGN(newBranch_, [COUUID UUIDWithString: [plist objectForKey: kCONewBranchUUID]]);
    
    return self;
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: [oldBranch_ stringValue] forKey: kCOOldBranchUUID];
    [result setObject: [newBranch_ stringValue] forKey: kCONewBranchUUID];
    [result setObject: kCOEditSetCurrentBranch forKey: kCOUndoAction];
    return result;
}

- (COEdit *) inverseForApplicationTo: (COPersistentRootState *)aProot
{
    return [[[[self class] alloc] initWithOldBranchUUID: newBranch_
                                          newBranchUUID: oldBranch_
                                                   UUID: uuid_
                                                   date: date_
                                            displayName: displayName_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRootState *)aProot
{
    [aProot setCurrentBranchUUID: newBranch_];
}

+ (BOOL) isUndoable
{
    return YES;
}

@end
