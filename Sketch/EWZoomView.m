#import "EWZoomView.h"

@implementation EWZoomView

- (CGFloat) zoom
{
	NSView *clipView = [[self documentView] superview];
	CGFloat factor = [clipView frame].size.width / [clipView bounds].size.width;
	
	return factor;
}

- (void) setZoom: (CGFloat)newZoom
{
	NSView *clipView = [[self documentView] superview];

	NSSize newBounds = NSMakeSize(NSWidth([clipView frame]) / newZoom,
								  NSHeight([clipView frame]) / newZoom);
	
	[clipView setBoundsSize: newBounds];
	[clipView setNeedsDisplay: YES];
}

- (void) scrollWheel: (NSEvent *)theEvent
{
	if (([theEvent modifierFlags] & NSAlternateKeyMask) != 0 )
	{   		
		CGFloat delta = MAX(-99.0, MIN(99.0, [theEvent deltaY])) / 100.0;  // (-1 .. 0 .. 1)
		
		CGFloat newZoom = [self zoom] * (1 + delta);
		
		if (newZoom > (1/100.0) && newZoom < 100)
		{
			[self setZoom: newZoom];
		}
	}
	else
	{
		[super scrollWheel: theEvent];
	}
}

@end
