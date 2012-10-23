#import <Cocoa/Cocoa.h>
#import "COPersistentRoot.h"

@interface EWBranchesWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView *table;
    COPersistentRoot *proot_;
}

+ (EWBranchesWindowController *) sharedController;

- (void) show;

@end
