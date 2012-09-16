#import "EWBranchesWindowController.h"

@implementation EWBranchesWindowController

- (id)init
{
	self = [super initWithWindowNibName: @"Branches"];
	return self;
}

+ (EWBranchesWindowController *) sharedController
{
    static EWBranchesWindowController *shared;
    if (shared == nil) {
        shared = [[self alloc] init];
    }
    return shared;
}

- (void) setInspectedDocument: (NSDocument *)aDoc
{
    NSLog(@"Inspect %@", aDoc);
}

- (void) show
{
    [self setInspectedDocument: [[NSDocumentController sharedDocumentController]
                                 currentDocument]];
    
    [self showWindow: self];
}
/* NSTableViewDataSource */

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return 1;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return @"Hello";
}

@end
