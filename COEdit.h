#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRootPlist.h"

NSString *kCOEditSetCurrentVersionForBranch;
NSString *kCOEditCreateBranch;
NSString *kCOEditSetCurrentBranch;
NSString *kCOEditGroup;
NSString *kCOEditSetMetadata;

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

+ (COEdit *) undoActionWithPlist: (id)aPlist;
- (id)plist;

- (COUUID*) persistentRootUUID;

- (NSDate*) date;
/**
 * Caller should prepend "Undo " or "Redo "
 */
- (NSString*) menuTitle;
- (COEdit *) inverseForApplicationTo: (COPersistentRootPlist *)aProot;

- (void) applyToPersistentRoot: (COPersistentRootPlist *)aProot;

+ (BOOL) isUndoable;

@end

