#import <Cocoa/Cocoa.h>

#import "EWUtilityWindowController.h"

@interface EWBranchesWindowController : EWUtilityWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView *table;
    COPersistentRootInfo *proot_;
}

+ (EWBranchesWindowController *) sharedController;

- (void) show;

@end
