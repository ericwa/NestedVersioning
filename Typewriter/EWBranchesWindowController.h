#import <Cocoa/Cocoa.h>
#import "COPersistentRootPlist.h"
#import "EWUtilityWindowController.h"

@interface EWBranchesWindowController : EWUtilityWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView *table;
    COPersistentRootPlist *proot_;
}

+ (EWBranchesWindowController *) sharedController;

- (void) show;

@end
