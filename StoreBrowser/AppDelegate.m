#import "AppDelegate.h"
#import "EWPersistentRootWindowController.h"

#import "Common.h"

@implementation AppDelegate

@synthesize window = _window;

- (id) init
{
	SUPERINIT;
	store = [[COStore alloc] initWithURL:
			 [NSURL fileURLWithPath: [@"~/om5teststore" stringByExpandingTildeInPath]]];
	windowControllerForPath = [[NSMutableDictionary alloc] init];
	return self;
}

- (void)dealloc
{
	[store release];
	[windowControllerForPath release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self browsePersistentRootAtPath: [COPath path]];
}

- (void) browsePersistentRootAtPath: (COPath*)aPath
{
	EWPersistentRootWindowController *wc = [windowControllerForPath objectForKey: aPath];
	
	if (wc == nil)
	{
		wc = [[EWPersistentRootWindowController alloc] initWithPath: aPath store: store];
		[windowControllerForPath setObject: wc forKey: aPath];
		[wc release];
	}
	
	[wc showWindow: nil];
}

@end
