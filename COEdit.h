#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRootState.h"

NSString *kCOEditSetCurrentVersionForBranch;
NSString *kCOEditCreateBranch;
NSString *kCOEditDeleteBranch;
NSString *kCOEditSetCurrentBranch;
NSString *kCOEditGroup;
NSString *kCOEditSetMetadata;
NSString *kCOEditSetBranchMetadata;

NSString *kCOUndoAction;

@interface COEdit : NSObject
{
    COUUID *uuid_;
    NSDate *date_;
    NSString *displayName_;
}
- (id) initWithPlist: (id)plist;
- (id) initWithUUID: (COUUID*)aUUID
               date: (NSDate*)aDate
        displayName: (NSString*)aName;

+ (COEdit *) editWithPlist: (id)aPlist;
- (id)plist;

- (COUUID*) persistentRootUUID;

- (NSDate*) date;
/**
 * Caller should prepend "Undo " or "Redo "
 */
- (NSString*) menuTitle;
- (COEdit *) inverseForApplicationTo: (COPersistentRootState *)aProot;

- (void) applyToPersistentRoot: (COPersistentRootState *)aProot;

+ (BOOL) isUndoable;

@end

