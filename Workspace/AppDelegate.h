#import <Cocoa/Cocoa.h>
#import "ManageWorkspacesWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *switchMenu;
@property (assign) IBOutlet ManageWorkspacesWindowController *manageWorkspacesWindowController;

@end
