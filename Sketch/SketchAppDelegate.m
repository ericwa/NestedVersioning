#import "SketchAppDelegate.h"
#import "EWProjectWindowController.h"
#import "EWDrawingWindowController.h"
#import "COMacros.h"

@implementation SketchAppDelegate

- (id) init
{
	SUPERINIT;
		
	store = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: [@"~/sketchstore" stringByExpandingTildeInPath]]];
	drawingWinControllerForPath = [[NSMutableDictionary alloc] init];
	projectWinController = [[EWProjectWindowController alloc] init];
	
	return self;
}

- (void)dealloc
{
	[store release];
	[drawingWinControllerForPath release];
	[projectWinController release];
    [super dealloc];
}

- (void) orderFrontProjectWindow: (id)sender
{
	[projectWinController showWindow: nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self orderFrontProjectWindow: nil];
}

- (EWDrawingWindowController *) drawingWinControllerForPath: (COPath*)aPath
{
	EWDrawingWindowController *wc = [drawingWinControllerForPath objectForKey: aPath];
	
	if (wc == nil)
	{

	}
	
	return wc;
}

@end
