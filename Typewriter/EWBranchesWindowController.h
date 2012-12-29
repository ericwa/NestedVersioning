#import <Cocoa/Cocoa.h>
#import "COPersistentRootState.h"
#import "EWUtilityWindowController.h"

@interface EWBranchesWindowController : EWUtilityWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView *table;
    COPersistentRootState *proot_;
}

+ (EWBranchesWindowController *) sharedController;

- (void) show;

@end
