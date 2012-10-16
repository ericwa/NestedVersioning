#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRoot.h"

NSString *kCOUndoActionSetCurrentVersionForBranch;
NSString *kCOUndoActionDeleteBranch;
NSString *kCOUndoActionSetCurrentBranch;
NSString *kCOUndoAction;

@interface COUndoAction : NSObject
{
    COUUID *uuid_;
    NSDate *date_;
    NSString *displayName_;
}
- (id) initWithPlist: (id)plist;
- (id) initWithUUID: (COUUID*)aUUID
               date: (NSDate*)aDate
        displayName: (NSString*)aName;

+ (COUndoAction *) undoActionWithPlist: (id)aPlist;
- (id)plist;

- (COUUID*) persistentRootUUID;

- (NSDate*) date;
/**
 * Caller should prepend "Undo " or "Redo "
 */
- (NSString*) menuTitle;
- (COUndoAction *) inverse;

- (void) applyToPersistentRoot: (COPersistentRoot *)aProot;

@end

