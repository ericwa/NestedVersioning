#import "EWHistoryGraphView.h"
#import "EWGraphRenderer.h"
#import "COMacros.h"

@implementation EWHistoryGraphView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (graphRenderer != nil)
	{
		[NSGraphicsContext saveGraphicsState];
		
		[[NSColor whiteColor] set];
		NSRectFill(dirtyRect);
		
		[graphRenderer draw];
		 
		 [NSGraphicsContext restoreGraphicsState];
	}
}

- (void) setGraphRenderer: (EWGraphRenderer *)aRenderer
{
	ASSIGN(graphRenderer, aRenderer);
	
	NSLog(@"Graph renderer size: %@", NSStringFromSize([graphRenderer size]));
	
	[self setFrameSize: [graphRenderer size]];
	[self setNeedsDisplay: YES];
}

@end
