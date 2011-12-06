#import "AppDelegate.h"
#import "EWPersistentRootWindowController.h"
#import "COStore.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	COStore *store = [[COStore alloc] initWithURL:
					  [NSURL fileURLWithPath: [@"~/om5teststore" stringByExpandingTildeInPath]]];
	EWPersistentRootWindowController *wc = [[EWPersistentRootWindowController alloc] initWithPath:[COPath path] store: store];
												
	[wc showWindow: nil];
}

@end
