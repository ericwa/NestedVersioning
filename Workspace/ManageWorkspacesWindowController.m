#import "ManageWorkspacesWindowController.h"

@interface ManageWorkspacesWindowController ()
@end

@implementation ManageWorkspacesWindowController

- (id)init
{
    self = [super initWithWindowNibName: @"ManageWorkspaces"];
    workspaces = [[NSMutableArray alloc] init];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
