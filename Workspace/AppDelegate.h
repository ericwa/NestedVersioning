#import <Cocoa/Cocoa.h>
#import "ManageWorkspacesWindowController.h"
#import <NestedVersioning/NestedVersioning.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    COStore *store_;
    COPersistentRoot *workspaces_;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *switchMenu;
@property (assign) IBOutlet ManageWorkspacesWindowController *manageWorkspacesWindowController;

@end
