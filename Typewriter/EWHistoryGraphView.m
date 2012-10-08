#import "EWHistoryGraphView.h"
#import "EWGraphRenderer.h"
#import "COMacros.h"
#import "COSubtreeDiff.h"


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

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
	COStore *store = [graphRenderer store];
	COUUID *commit = [graphRenderer commitAtPoint: point];
	
	if (commit == nil)
	{
		return nil;
	}
	
	NSMutableString *desc = [NSMutableString string];
	
    [desc appendString: @"todo"];
    
//	[desc appendFormat: @"%@", commit];
//	
//	COUUID *parent = [store parentForCommit: commit];
//	if (nil != parent)
//	{
//		COSubtree *before = [store treeForCommit: parent];
//		COSubtree *after = [store treeForCommit: commit];
//		COSubtreeDiff *diff = [COSubtreeDiff diffSubtree: before withSubtree: after sourceIdentifier: @""];
//		
//		[desc appendFormat: @"\n\n%@", diff];
//	}
	
	return desc;
}

- (void) setGraphRenderer: (EWGraphRenderer *)aRenderer
{
	ASSIGN(graphRenderer, aRenderer);
	
	//NSLog(@"Graph renderer size: %@", NSStringFromSize([graphRenderer size]));
	
	[self setFrameSize: [graphRenderer size]];
	[self setNeedsDisplay: YES];
	
	// Update tooltips
	
	[self removeAllToolTips];
	for (COUUID *commit in [graphRenderer commits])
	{
		NSRect r = [graphRenderer rectForCommit: commit];
		[self addToolTipRect:r owner:self userData:commit];
	}
}

- (void) setCurrentCommit: (COUUID *)aCommit
{
	ASSIGN(currentCommit, aCommit);
	[self setNeedsDisplay: YES];
}

- (NSMenu *) menuForEvent: (NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint: [theEvent locationInWindow] 
						   fromView: nil];
	
    COUUID *commit = [graphRenderer commitAtPoint: pt];
	
	if (nil != commit)
	{
		NSMenu *menu = [[[NSMenu alloc] initWithTitle: @""] autorelease];

		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Diff with Current Commit" 
														   action: @selector(diffCommits:) 
													keyEquivalent: @""] autorelease];
			[item setRepresentedObject: A(currentCommit, commit)];
			[menu addItem: item];
		}		
		
		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Selective Undo" 
														   action: @selector(selectiveUndo:) 
													keyEquivalent: @""] autorelease];
			[item setRepresentedObject: commit];
			[menu addItem: item];
		}

		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Selective Apply" 
														   action: @selector(selectiveApply:) 
													keyEquivalent: @""] autorelease];
			[item setRepresentedObject: commit];
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
		
		COUUID *commit = [graphRenderer commitAtPoint: pt];
		[NSApp sendAction: @selector(switchToCommit:) to: nil from: commit];
	}
}

@end
