#import <Cocoa/Cocoa.h>

@interface EWBranchesWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView *table;
}

+ (EWBranchesWindowController *) sharedController;

- (void) show;

@end
