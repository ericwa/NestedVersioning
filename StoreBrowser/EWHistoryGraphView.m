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
	
	//NSLog(@"Graph renderer size: %@", NSStringFromSize([graphRenderer size]));
	
	[self setFrameSize: [graphRenderer size]];
	[self setNeedsDisplay: YES];
	
	// Update tooltips
	
	[self removeAllToolTips];
	for (ETUUID *commit in [graphRenderer commits])
	{
		NSRect r = [graphRenderer rectForCommit: commit];
		
		// FIXME: relies on commit being owned by the array in graphRenderer
		[self addToolTipRect:r owner:commit userData:nil];
	}
}

- (void) setCurrentCommit: (ETUUID *)aCommit
{
	ASSIGN(currentCommit, aCommit);
	[self setNeedsDisplay: YES];
}

- (NSMenu *) menuForEvent: (NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint: [theEvent locationInWindow] 
						   fromView: nil];
	
    ETUUID *commit = [graphRenderer commitAtPoint: pt];
	
	if (nil != commit)
	{
		NSMenu *menu = [[[NSMenu alloc] initWithTitle: @""] autorelease];
		
		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Selective Undo" 
														   action: @selector(selectiveUndo:) 
													keyEquivalent: @""] autorelease];
			[item setTarget: self];
			[menu addItem: item];
		}

		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Selective Apply" 
														   action: @selector(selectiveApply:) 
													keyEquivalent: @""] autorelease];
			[item setTarget: self];
			[menu addItem: item];
		}

		[menu addItem: [NSMenuItem separatorItem]];
		
		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Switch To Commit" 
														   action: @selector(switchToCommit:) 
													keyEquivalent: @""] autorelease];
			[item setRepresentedObject: commit];
			[menu addItem: item];
		}
		
		return menu;
	}
	return nil;
}

- (void)mouseUp: (NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2)
	{
		NSPoint pt = [self convertPoint: [theEvent locationInWindow] 
							   fromView: nil];
		
		ETUUID *commit = [graphRenderer commitAtPoint: pt];
		[NSApp sendAction: @selector(switchToCommit:) to: nil from: commit];
	}
}

@end
