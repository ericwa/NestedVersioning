#import <Foundation/Foundation.h>

#import <EtoileFoundation/ETUUID.h>
#import "COSQLiteStore.h"

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
    ETUUID *uuid_;
    NSDate *date_;
    NSString *displayName_;
}
- (id) initWithPlist: (id)plist;
- (id) initWithUUID: (ETUUID*)aUUID
               date: (NSDate*)aDate
        displayName: (NSString*)aName;

+ (COEdit *) editWithPlist: (id)aPlist;
- (id)plist;

- (ETUUID*) persistentRootUUID;

- (NSDate*) date;
/**
 * Caller should prepend "Undo " or "Redo "
 */
- (NSString*) menuTitle;
- (COEdit *) inverseForApplicationTo: (COPersistentRootInfo *)aProot;

- (void) applyToPersistentRoot: (COPersistentRootInfo *)aProot;

+ (BOOL) isUndoable;

@end

