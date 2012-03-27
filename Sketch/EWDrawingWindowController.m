#import "EWDrawingWindowController.h"
#import "EWZoomView.h"

@implementation EWDrawingWindowController

- (id) init
{
	self = [super initWithWindowNibName: @"DrawingWindow"];
	if (nil != self)
	{
		
	}
	return self;
}

- (void)windowDidLoad
{
	[widthField setDoubleValue: 8.5];
	[heightField setDoubleValue: 11];
	
	NSButton *button = [[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
	[button setBezelStyle: NSRoundedBezelStyle];
	[button setBordered: YES];
	[button setTitle: @"hello"];
	
	[[scrollView documentView] addSubview: button];
}

- (void) changeSize: (id)sender
{
	NSLog(@"width: %f height: %f", [widthField doubleValue], [heightField doubleValue]);
}

@end
