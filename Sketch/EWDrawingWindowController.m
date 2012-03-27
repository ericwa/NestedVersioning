#import "EWDrawingWindowController.h"

@implementation EWDrawingWindowController

- (id) init
{
	self = [super initWithWindowNibName: @"DrawingWindow"];
	if (nil != self)
	{
		
	}
	return self;
}

- (void) changeSize: (id)sender
{
	NSLog(@"width: %f height: %f", [widthField doubleValue], [heightField doubleValue]);
}

@end
