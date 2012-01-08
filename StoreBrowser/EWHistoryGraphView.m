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
		
		[graphRenderer drawWithHighlightedCommit: currentCommit];
		 
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

- (void) setCurrentCommit: (ETUUID *)aCommit
{
	ASSIGN(currentCommit, aCommit);
	[self setNeedsDisplay: YES];
}

@end
