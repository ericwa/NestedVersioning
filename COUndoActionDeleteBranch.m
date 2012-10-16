#import "COUndoActionDeleteBranch.h"
#import "COMacros.h"
#import "COBranch.h"

@implementation COUndoActionDeleteBranch : COUndoAction

static NSString *kCOBranchBackup = @"COBranchBackup";
static NSString *kCOIsUndoingCreation = @"COIsUndoingCreation";

- (id) initWithBranch: (COBranch *)aBranch
    isUndoingCreation: (BOOL)unudoCreation
                 UUID: (COUUID*)aUUID
                 date: (NSDate*)aDate
          displayName: (NSString*)aName
{
    self = [super initWithUUID: aUUID date: aDate displayName: aName];
    ASSIGN(branch_, [[aBranch mutableCopy] autorelease]);
    undoCreate_ = unudoCreation;    
    return self;
}


- (id) initWithPlist: (id)plist
{
    self = [super initWithPlist: plist];
    
    ASSIGN(branch_, [COBranch _branchWithPlist: [plist objectForKey: kCOBranchBackup]]);
    undoCreate_ = [[plist objectForKey: kCOIsUndoingCreation] boolValue];
    return self;
}

- (id)plist
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary: [super plist]];
    [result setObject: [branch_ _plist] forKey: kCOBranchBackup];
    [result setObject: [NSNumber numberWithBool: undoCreate_] forKey: kCOIsUndoingCreation];
    [result setObject: kCOUndoActionDeleteBranch forKey: kCOUndoAction];
    return result;
}

- (COUndoAction *) inverse
{
    return [[[[self class] alloc] initWithBranch: branch_
                               isUndoingCreation: !undoCreate_
                                            UUID: uuid_
                                            date: date_
                                     displayName: displayName_] autorelease];
}

- (void) applyToPersistentRoot: (COPersistentRoot *)aProot
{
    if (undoCreate_)
    {
        [aProot deleteBranch: [branch_ UUID]];
    }
    else
    {
        [aProot addBranch: branch_];
    }
}

@end
