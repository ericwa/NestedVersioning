#import "EWOutlineView.h"

@implementation EWOutlineView

- (NSMenu *) menuForEvent: (NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint: [theEvent locationInWindow] 
						   fromView: nil];
    id item = [self itemAtRow: [self rowAtPoint: pt]];
    return [item menu];
}

/**
 * Makes right click affect selection in the same way that left click does
 * (right click inside seletion: no change.
 *  right click outside selection: select row under right click)
 */
- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSUInteger row = [self rowAtPoint:pt];
	if (![self isRowSelected: row])
	{
		[self selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
		  byExtendingSelection: NO];
	}
	[super rightMouseDown: theEvent];
}

@end
