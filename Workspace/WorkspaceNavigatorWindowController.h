#import <Cocoa/Cocoa.h>

@interface WorkspaceNavigatorWindowController : NSWindowController
{
    NSMutableArray *tree;
    IBOutlet NSOutlineView *treeOutline;
}

@end
