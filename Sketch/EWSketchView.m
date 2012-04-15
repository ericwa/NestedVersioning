#import "EWSketchView.h"
#import "EWBezierPath.h"


@implementation EWSketchView

- (void) drawRect: (NSRect)dirtyRect
{
	[[NSColor whiteColor] set];
	NSRectFill([self bounds]);
	
	
	NSFont *font = [NSFont fontWithName: @"Helvetica" size: 12];
	NSBezierPath *test = [NSBezierPath bezierPath];
	[test moveToPoint: NSMakePoint(0,0)];
	[test appendBezierPathWithGlyph: [font glyphWithName: @"a"] inFont: font];
	
	COSubtree *subtree = [EWBezierPath subtreeFromBezierPath: test];
	NSBezierPath *back = [EWBezierPath bezierPathFromSubtree: subtree];
	
	[[NSColor greenColor] set];
	[back fill];
	
	NSLog(@"%d", [back isEqual: test]);
}

@end
