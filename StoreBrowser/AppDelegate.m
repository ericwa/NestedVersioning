#import "AppDelegate.h"
#import "EWPersistentRootWindowController.h"
#import "TestCommon.h"
#import "COMacros.h"

@implementation AppDelegate

@synthesize window = _window;

- (id) init
{
	SUPERINIT;
	
	// Set up a demo store
	
	testTagging();
	
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

- (EWPersistentRootWindowController *) windowControllerForPath: (COPath*)aPath
{
	EWPersistentRootWindowController *wc = [windowControllerForPath objectForKey: aPath];
	
	if (wc == nil)
	{
		wc = [[EWPersistentRootWindowController alloc] initWithPath: aPath store: store];
		[windowControllerForPath setObject: wc forKey: aPath];
		[wc release];
	}
	
	return wc;
}

- (void) browsePersistentRootAtPath: (COPath*)aPath
{
	[[self windowControllerForPath: aPath] showWindow: nil];
}

- (void) reloadAllBrowsers
{
	for (EWPersistentRootWindowController *wc in [windowControllerForPath allValues])
	{
		[wc reloadBrowser];
	}
}

@end
