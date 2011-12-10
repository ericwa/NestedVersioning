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
		[[NSColor greenColor] set];
		NSRectFill(dirtyRect);
	}
}

- (void) setGraphRenderer: (EWGraphRenderer *)aRenderer
{
	ASSIGN(graphRenderer, aRenderer);
}

@end
