#import "WorkspaceNavigatorWindowController.h"

@interface WorkspaceNavigatorWindowController ()

@end

@implementation WorkspaceNavigatorWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"WorkspaceNavigator"];
    if (self) {
        tree = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSLog(@"treeOutline:%@ ds: %@", treeOutline, [treeOutline dataSource]);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSLog(@"sel changed");
}

@end
