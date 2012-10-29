#import <Cocoa/Cocoa.h>
#import "COPersistentRoot.h"
#import "EWUtilityWindowController.h"

@interface EWBranchesWindowController : EWUtilityWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView *table;
    COPersistentRoot *proot_;
}

+ (EWBranchesWindowController *) sharedController;

- (void) show;

@end
