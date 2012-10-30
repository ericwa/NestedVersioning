#import <Cocoa/Cocoa.h>
#import "COPersistentRoot.h"
#import "EWUtilityWindowController.h"

@class EWDocument;

@interface EWBranchesWindowController : EWUtilityWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView *table;
    EWDocument *inspectedDoc_;
}

+ (EWBranchesWindowController *) sharedController;

- (void) show;

@end
