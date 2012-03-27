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
		CGFloat delta = [theEvent deltaY];
		
		if (delta > 0)
		{		
			[self setZoom: [self zoom] * 1.1];
		}
		else if (delta < 0)
		{
			[self setZoom: [self zoom] * 0.9];
		}
	}
	else
	{
		[super scrollWheel: theEvent];
	}
}

@end
