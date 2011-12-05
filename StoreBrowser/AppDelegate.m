#import "AppDelegate.h"
#import "EWPersistentRootWindowController.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	EWPersistentRootWindowController *wc = [[EWPersistentRootWindowController alloc] 
												initWithWindowNibName: @"PersistentRootWindow"];
	[wc showWindow: nil];
}

@end
